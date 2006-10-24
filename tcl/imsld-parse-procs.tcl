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

ad_proc -public imsld::parse::convert_time_to_seconds {
    -time
} {
    Converts the time string (described in the spec) into seconds to easy the manipulation of this datatype. 
    @param time The time string
} {
    set time [string tolower $time]
    regsub -all {[^0-9pymdths]} $time "" time
    set years 0
    set months 0
    set days 0
    set hours 0
    set minutes 0
    set seconds 0
    set t_parsed 0
    set time_length [string length $time]
    while { [string length $time] } {
        regexp {^([0-9]*)([pymdthms])} $time match amount component
        switch $component {
            y {
                set years $amount
            }
            m {
                if { !$t_parsed } {
                    set months $amount
                } else {
                    set minutes $amount
                }
            }
            d {
                set days $amount
            }
            t {
                set t_parsed 1
            }
            h {
                set hours $amount
            }
            s {
                set seconds $amount
            }
        }
        regsub ${amount}${component} $time "" time
    }
    set seconds [expr ($years*946080000 + $months*2592000 + $days*86400 + $hours*3600 + $minutes*60 + $seconds)]
    return $seconds
}

ad_proc -public imsld::parse::get_URI {
    -type:required
} {
    Returns the URI corresponding to the indicated namespace in "type"
} {
   switch $type {
        "imsld" {
            set uri "http://www.imsglobal.org/xsd/imsld_v1p0"
        } 
        "imscp" {
            set uri "http://www.imsglobal.org/xsd/imscp_v1p1"           
        }
        "imsmd" {
            set uri "http://www.imsglobal.org/xsd/imsmd_v1p2"           
        }
        "xsi" {
            set uri "http://www.w3.org/2001/XMLSchema-instance"           
        }
   }
   return $uri
}

ad_proc -public imsld::parse::is_imsld {
    -tree:required
} {
    Checks if the given tree has the IMS LD extension and if the IMS LD comes in the organization.

    Returns a list (pair of values): 1 + empty if succeeded, 0 + error message otherwise.

    @param tree XML tree to analyze.
} {

#Check the base URI

if { ![string eq [$tree namespaceURI] [imsld::parse::get_URI -type "imscp"] ]} {
        return -code error "IMSLD:imsld::parse::is_imsld: [_ imsld.lt_manifest_namespace_is]"
    }
# Check organizations
    set organizations [ $tree selectNodes { *[local-name()='organizations'] } ] 
    if { ![string eq [$organizations namespaceURI] [imsld::parse::get_URI -type "imscp"] ] } {
        return -code error "IMSLD:imsld::parse::is_imsld: [_ imsld.lt_organizations_tag_not]"
    }
        imsld::parse::validate_multiplicity -tree $organizations -multiplicity 1 -element_name organizations -equal

# Check learning-design tag 
     set ld_tag [ $organizations selectNodes { *[local-name()='learning-design'] } ]
     if { ! [string eq [$ld_tag namespaceURI] [imsld::parse::get_URI -type "imsld"] ] } {
        return -code error "IMSLD:imsld::parse::is_imsld: [_ imsld.lt_learning-desing_tag_n]"
    }
    imsld::parse::validate_multiplicity -tree $ld_tag -multiplicity 1 -element_name IMD-LD -equal

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
        form set_error upload_file_form upload_file "[_ imsld.lt_There_was_an_error_ge] $errmsg"
        return -code error "IMSLD::imsld::parse::expand_file: Error generating tmp directory: $errmsg"
    }

    # Create a temporary directory
    if { [catch {file mkdir $tmp_dir} errmsg] } {
        form set_error upload_file_form upload_file "[_ imsld.lt_There_was_an_error_cr_1] $errmsg"
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
        set type "[_ imsld.Uknown_type]" 
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
            
            # Therefore it if it is 1, then it concluded successfully
            # but with warnings, so we switch it back to 0
            
            if { $error_p == 1 } {
                set error_p 0
            }
        }
        default {
            set error_p 1
            set errmsg "[_ imsld.lt_Could_not_determine_w]"
        }
    }
    
    if { $error_p } {
        ns_log Notice "IMSLD::imsld::parse::expand_file: extract type $type failed $errmsg"
        imsld::parse::remove_dir -dir $tmp_dir
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
    set titles_list [$node selectNodes {*[local-name()='title']}]
    if { [llength $titles_list] == 1} {
        set name_space [$titles_list namespaceURI]
        if { [string eq [imsld::parse::get_URI -type "imsld"] $name_space] } {
            imsld::parse::validate_multiplicity -tree $titles_list -multiplicity 1 -element_name title -equal
            return [imsld::parse::get_element_text -node $titles_list]
        } else {
            return ""
        } 
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
        return -code error "IMSLD:imsld::parse::validate_multiplicity: [_ imsld.lt_More_than_one_validat]"
    }
    if { ![expr $equal_p + $greather_than_p + $lower_than_p] } {
        set equal_p 1
    }

    set tree_length [llength $tree]
    if { $equal_p } {
        if { $tree_length != $multiplicity } {
            ad_return_error "[_ imsld.Error_parsing_file]" "[_ imsld.lt_There_must_be_exactly]"
            ad_script_abort
        }
    } elseif { $greather_than_p } {
        if { $tree_length < $multiplicity } {
            ad_return_error "[_ imsld.Error_parsing_file]" "[_ imsld.lt_There_cant_be_less_th]"
            ad_script_abort
        } 
    } else {
        if { $tree_length > $multiplicity } {
            ad_return_error "[_ imsld.Error_parsing_file]" "[_ imsld.lt_There_cant_greather_t]"
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
    if { [catch {file delete -force -- $dir} errmsg] } {
        return -code error "IMSLD:imsld::parse::remove_dir: [_ imsld.lt_There_was_an_error_tr] $errmsg"
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

    Returns a list of two elements, the first one is the folder_id in the fs of the root folder for that manifest, and the ohter one is the folder_id where the cr items and revisions are stored.
    
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
    
    set fs_root_folder_id [fs::get_root_folder -package_id $fs_package_id]
    set cr_root_folder_id [imsld::cr::get_root_folder -community_id $community_id]

    set fs_folder_id [content::item::get_id -item_path "manifest_${manifest_id}" -root_folder_id $fs_root_folder_id -resolve_index f] 
    set cr_folder_id [content::item::get_id -item_path "cr_manifest_${manifest_id}" -root_folder_id $cr_root_folder_id -resolve_index f] 

    if { [empty_string_p $fs_folder_id] } {
        db_transaction {
            set folder_name "manifest_${manifest_id}"

            # checks for write permission on the parent folder
            if { ![empty_string_p $fs_root_folder_id] } {
                ad_require_permission $fs_root_folder_id write
            }

            # create the root cr dir

            set fs_folder_id [imsld::cr::folder_new -parent_id $fs_root_folder_id -folder_name $folder_name -folder_label $folder_label]

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
        set cr_folder_id [imsld::cr::folder_new -folder_name $folder_name -folder_label $folder_label -parent_id $cr_root_folder_id]
        
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
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_complete_act
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
    {-activity_name ""}
    -resource_node
    -parent_id
    -tmp_dir
} {
    Parses an IMS-LD resource and stores all the information in the database, such as files, dependencies, etc

    Returns a list with the new resource_id created if there were no errors, or 0 and an error explanation.
    
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @option activity_name In case the resource forms part of an activity, the name is passed to name the possible acs_object associated
    @param resource_node Resource tree being parsed
    @param parent_id Parent folder ID
    @tmp_dir Temporary directory where the files were exctracted
} {
    upvar files_struct_list files_struct_list
    # verify that the resource hasn't been already created
    set resource_identifier [imsld::parse::get_attribute -node $resource_node -attr_name identifier]
    if { ![db_0or1row redundancy_protection {
        select item_id as resource_id 
        from imsld_cp_resourcesi
        where identifier = :resource_identifier
        and manifest_id = :manifest_id
    }] } {
        # now we proceed to get all the info of the resource
        set resource_type [imsld::parse::get_attribute -node $resource_node -attr_name type]
        set resource_href [imsld::parse::get_attribute -node $resource_node -attr_name href]
        set community_id [dotlrn_community::get_community_id]
        
        if { [string eq $resource_type forum] } {
            # particular case specially treated in .LRN
            # (this is not part of the spec)
            set acs_object_id [imsld::parse::parse_and_create_forum -name $activity_name]
        } else {
            set acs_object_id [callback -catch imsld::import -res_type $resource_type -res_href $resource_href -tmp_dir $tmp_dir -community_id $community_id]
        }
        # Integration with other packages
        # This callback gets the href of the imported content (if some package imported it)

        #revoke permissions until first usage of resources
        if {[info exist acs_object_id]} {
            permission::set_not_inherit -object_id $acs_object_id
            set party_id [db_list get_allowed_parties {}]
            foreach parti $party_id {
                permission::revoke -party_id $parti -object_id $acs_object_id -privilege "read"
            }
        }
        
        set resource_id [imsld::cp::resource_new -manifest_id $manifest_id \
                             -identifier $resource_identifier \
                             -type $resource_type \
                             -href $resource_href \
                             -acs_object_id $acs_object_id \
                             -parent_id $parent_id]
        
        set found_p 0
        
        set filex_list [$resource_node selectNodes {*[local-name()='file']}]
        
        set found_id_in_list 0
        foreach filex $filex_list {
            set filex_href [imsld::parse::get_attribute -node $filex -attr_name href]
            set filex_id [imsld::fs::file_new -href $filex_href \
                              -path_to_file $filex_href \
                              -type file \
                              -complete_path "[ns_urldecode ${tmp_dir}/${filex_href}]"]
            
            if { !$filex_id } {
                # an error ocurred when creating the file
                return [list 0 "[_ imsld.lt_The_file_filex_href_w]"]
            }
            if { ![empty_string_p $resource_href] && [string eq $resource_href $filex_href] } {
                # check if the referenced file in the resource exists
                # if we finish with the files and the referenced one doesn't exist we raise an error
                set found_p 1
                set extra_vars [util_list_to_ns_set [list displayable_p "t"]]
            } elseif { [empty_string_p $resource_href] && [string eq $first_id_in_list 0] } {
                set extra_vars [util_list_to_ns_set [list displayable_p "t"]]
            } else {
                set extra_vars [util_list_to_ns_set [list displayable_p "f"]]
            }

            permission::set_not_inherit -object_id $filex_id
            
            set acs_object_id $filex_id 
            set party_id_list [db_list get_allowed_parties {}]
            foreach party_id $party_id_list {
                permission::revoke -party_id $party_id -object_id $filex_id -privilege "read"
            }
            
            # map resource with file
            relation_add -extra_vars $extra_vars imsld_res_files_rel $resource_id $filex_id
        }
        
        if { ![empty_string_p $resource_href] && !$found_p } {
            # the file is not in the manifest, assming it's an external (and existing) url
            set link_id [content::extlink::new -url $resource_href \
                             -parent_id $parent_id]
            # map resource with file
            set extra_vars [util_list_to_ns_set [list displayable_p "t"]]
            relation_add -extra_vars $extra_vars imsld_res_files_rel $resource_id $link_id
        }
        

        set resource_dependencies [$resource_node selectNodes {*[local-name()='dependency']}]

        
        foreach dependency $resource_dependencies {
            set dependency_identifierref [imsld::parse::get_attribute -node $dependency -attr_name identifierref]
            set dependency_id [imsld::cp::dependency_new -resource_id $resource_id \
                                   -identifierref $dependency \
                                   -parent_id $parent_id]
            # look for the resource in the manifest and add it to the CR

            set resources [$manifest selectNodes {*[local-name()='resources'] }]
            
            # there must be at least one reource for the learning objective
            imsld::parse::validate_multiplicity -tree $resources -multiplicity 0 -element_name "resources (dependency)" -greather_than
            
            set resourcex [$resources find identifier $dependency_identifierref]
            # this resourcex must match with exactly one resource
            imsld::parse::validate_multiplicity -tree $resourcex -multiplicity 1 -element_name "resource ($dependency_identifierref) en $resourcex" -equal
            set dependency_resource_list [imsld::parse::parse_and_create_resource -resource_node $resourcex \
                                              -manifest $manifest \
                                              -manifest_id $manifest_id \
                                              -activity_name $activity_name \
                                              -parent_id $parent_id \
                                              -tmp_dir $tmp_dir]
            if { ![lindex $dependency_resource_list 0] } {
                # return this value and let the user know there was an error (becuase if succeded, it does nothing here)
                return $dependency_resource_list
            }
        }
    }
    return [list $resource_id {}]
}

ad_proc -public imsld::parse::parse_and_create_item { 
    -manifest
    -manifest_id
    {-activity_name ""}
    -item_node
    -parent_id
    -tmp_dir
    {-parent_item_id ""}
} {
    Parse IMS-LD item node and stores all the information in the database, such as the resources, resources items, etc.

    Returns a list with the new imsld_item_id created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @option activity_name In case the item is asociated with an activity, the name is pased to hame the possible associated objects which require pretty names
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
    set item_id [imsld::item_revision_new -title $item_title \
                     -content_type imsld_item \
                     -attributes [list [list identifier $item_identifier] \
                                      [list is_visible_p $item_is_visible_p] \
                                      [list parameters $item_parameters] \
                                      [list identifierref $item_identifierref] \
                                      [list parent_item_id $parent_item_id]] \
                     -parent_id $parent_id]

    if { ![empty_string_p $item_identifierref] } {
        # look for the resource in the manifest and add it to the CR
        set resources [$manifest selectNodes {*[local-name()='resources']}]
        
        # there must be at least one reource for the learning objective
        imsld::parse::validate_multiplicity -tree $resources -multiplicity 1 -element_name "resources (referenced from item $item_identifier)" -greather_than

        set resourcex [$resources find identifier $item_identifierref]
        # this resourcex must match with exactly one resource
        imsld::parse::validate_multiplicity -tree $resourcex -multiplicity 1 -element_name "resources ($item_identifierref)" -equal
        set resource_list [imsld::parse::parse_and_create_resource -resource_node $resourcex \
                               -manifest $manifest \
                               -manifest_id $manifest_id \
                               -activity_name $activity_name \
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
    set nested_item_list [$item_node selectNodes {*[local-name()='item'] } ]
    if { [llength $nested_item_list] } {
        foreach nested_item $nested_item_list {
            set nested_item_list [imsld::parse::parse_and_create_item -manifest $manifest \
                                      -manifest_id $manifest_id \
                                      -item_node $nested_item \
                                      -activity_name $activity_name \
                                      -parent_id $parent_id \
                                      -tmp_dir $tmp_dir \
                                      -parent_item_id $item_id]
            
            set nested_item_id [lindex $nested_item_list 0]
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

    Returns a list with the new role_id (item_id) created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param role_type staff or learner
    @param component_id Component identifier which this role belongs to
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param roles_node The role node to parse 
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
    @option parent_role_id Parent role identifier. Default to null
} {
    upvar files_struct_list files_struct_list

    # get the info of the role node and create the respective role
    set role_create_new [imsld::parse::get_attribute -node $roles_node -attr_name create-new]
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
    set role_href [imsld::parse::get_attribute -node $roles_node -attr_name href]
    set role_identifier [imsld::parse::get_attribute -node $roles_node -attr_name identifier]
    set role_match_persons [imsld::parse::get_attribute -node $roles_node -attr_name match-persons]
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
    set role_max_persons [imsld::parse::get_attribute -node $roles_node -attr_name max-persons]
    set role_min_persons [imsld::parse::get_attribute -node $roles_node -attr_name min-persons]
    set role_title [imsld::parse::get_title -node $roles_node -prefix imsld]
    
    # create the role
    set role_id [imsld::item_revision_new -attributes [list [list identifier $role_identifier] \
                                                           [list role_type $role_type] \
                                                           [list parent_role_id $parent_role_id] \
                                                           [list create_new_p $role_create_new_p] \
                                                           [list match_persons_p $role_match_persons_p] \
                                                           [list max_persons $role_max_persons] \
                                                           [list min_persons $role_min_persons] \
                                                           [list href $role_href] \
                                                           [list component_id $component_id]] \
                     -content_type imsld_role \
                     -title $role_title \
                     -parent_id $parent_id]
    
    # continue with the role information and nested roles
                    
    set role_information [$roles_node selectNodes {*[local-name()='information'] } ]
    if { [llength $role_information] } {
        # parse the item, create it and map it to the role
        set information_item [$role_information selectNodes {*[local-name()='item'] } ]
        if { ![llength $information_item] } {
            return [list 0 "[_ imsld.lt_Information_given_but]"]
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
    set nested_roles [$roles_node selectNodes "*\[local-name()=\"$role_type\"\]"]
    if { [llength $nested_roles] } {
        foreach nested_role $nested_roles {
            set role_list [imsld::parse::parse_and_create_role -role_type $role_type \
                               -manifest $manifest \
                               -manifest_id $manifest_id \
                               -parent_id $parent_id \
                               -tmp_dir $tmp_dir \
                               -roles_node $nested_role \
                               -parent_role_id $role_id \
                               -component_id $component_id]
            if { ![lindex $role_list 0] } {
                # an error happened, abort and return the list whit the error
                return $role_list
            }
        }
    }
    return $role_id
}

ad_proc -public imsld::parse::parse_and_create_restriction { 
    -restriction_node
    -property_id
    -identifier
    -component
    -existing_href
    -manifest
    -manifest_id
    -parent_id
    -tmp_dir
} {
    Parse a restriction and stores all the information in the database.

    Returns a list with the new restriction_id (item_id) created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param restriction_node restriction node to parse
    @param property_id property_id
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
} {
    upvar files_struct_list files_struct_list
 
    set restriction_type [string tolower [imsld::parse::get_attribute -node $restriction_node -attr_name restriction-type]]
    set restriction_value [imsld::parse::get_element_text -node $restriction_node]
    set restriction_id [imsld::item_revision_new -attributes [list [list property_id $property_id] \
                                                                  [list restriction_type $restriction_type] \
                                                                  [list value $restriction_value]] \
                            -content_type imsld_restriction \
                            -parent_id $parent_id
                       ]
    return $restriction_id
}

ad_proc -public imsld::parse::parse_and_create_global_def { 
    {-global_def_node ""}
    -identifier
    -existing_href
    -component_id
    -type
    -manifest
    -manifest_id
    -parent_id
    -tmp_dir
} {
    Parse a global definition and stores all the information in the database.

    Returns a list with the new global_definition_id (item_id, actually a property_id) created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @option global_def_node global_def node to parse
    @param identifier
    @param existing_href
    @param component_id Comoponent id of the one which owns the property
    @param type Type of the property defined by this global definition, which can be globpers or glob
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
} {
    upvar files_struct_list files_struct_list
    
    if { ![empty_string_p $global_def_node] } {
        set uri [imsld::parse::get_attribute -node $global_def_node -attr_name uri]
        set title [imsld::parse::get_title -node $global_def_node -prefix imsld]
        set datatype [$global_def_node selectNodes "*\[local-name()='datatype'\]" ] 
        imsld::parse::validate_multiplicity -tree $global_def_node -multiplicity 1 -element_name "global-definition datatype" -equal
        set datatype [string tolower [imsld::parse::get_attribute -node $global_def_node -attr_name datatype]]
        set initial_value [$global_def_node selectNodes "*\[local-name()='initial-value'\]"] 
        imsld::parse::validate_multiplicity -tree $initial_value -multiplicity 1 -element_name "global-definition initial-value" -lower_than
        if { [llength $initial_value] } {
            set initial_value [imsld::parse::get_element_text -node $initial_value]
        } else {
            set initial_value ""
        }
    } else {
        set uri ""
        set datatype ""
        set initial_value ""
        set title ""
    }


    set globpers_property_id [imsld::item_revision_new -attributes [list [list component_id $component_id] \
                                                                  [list identifier $identifier] \
                                                                  [list existing_href $existing_href] \
                                                                  [list uri $uri] \
                                                                  [list type $type] \
                                                                  [list datatype $datatype] \
                                                                  [list initial_value $initial_value]] \
                            -content_type imsld_property \
                            -title $title \
                            -parent_id $parent_id]

    if { ![empty_string_p $global_def_node] } {
        set restrictions [$global_def_node selectNodes "*\[local-name()='restriction'\]"]
        foreach restriction $restrictions {
            set restriction_list [imsld::parse::parse_and_create_restriction -manifest $manifest \
                                      -property_id $globpers_property_id \
                                      -manifest_id $manifest_id \
                                      -restriction_node $restriction \
                                      -parent_id $parent_id \
                                      -tmp_dir $tmp_dir]
            
            set restriction_id [lindex $restriction_list 0]
            if { !$restriction_id } {
                # an error happened, abort and return the list whit the error
                return $restriction_list
            }
        }
    }
    return $globpers_property_id
}

ad_proc -public imsld::parse::parse_and_create_property_group { 
    -property_group_node
    -component_id
    -manifest
    -manifest_id
    -parent_id
    -tmp_dir
} {
    Parse a property group and stores all the information in the database.

    Returns a list with the new property_group_id (item_id) created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param property_group_node property_group node to parse
    @param component_id Component identifier of the one that owns this property
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
} {
    upvar files_struct_list files_struct_list
    
    set identifier [imsld::parse::get_attribute -node $property_group_node -attr_name identifier]
    set title [imsld::parse::get_title -node $property_group_node -prefix imsld]

    set property_group_id [imsld::item_revision_new -attributes [list [list identifier $identifier] \
                                                                     [list component_id $component_id]] \
                               -content_type imsld_property_group \
                               -title $title \
                               -parent_id $parent_id]

    set property_refs [$property_group_node selectNodes "*\[local-name()='property-ref'\]"]
    foreach property $property_refs {
        set ref [imsld::parse::get_attribute -node $property -attr_name ref]
        if { ![db_0or1row get_property_id {
            select item_id as property_item_id 
            from imsld_propertiesi 
            where identifier = :ref 
            and content_revision__is_live(property_id) = 't' 
            and component_id = :component_id
        }] } {
            # there is no property with that identifier, return the error
            return [list 0 "[_ imsld.lt_There_is_no_property_]"]
        }
        relation_add imsld_gprop_prop_rel $property_group_id $property_item_id
    }

    set property_group_refs [$property_group_node selectNodes "*\[local-name()='property-group-ref'\]"]
    foreach property_group $property_group_refs {
        set ref [imsld::parse::get_attribute -node $property_group -attr_name ref]
        if { ![db_0or1row get_group_property_id {
            select item_id as group_property_item_id 
            from imsld_propertiesi 
            where identifier = :ref 
            and content_revision__is_live(property_id) = 't' 
            and component_id = :component_id
        }] } {
            # there is no propety group with that identifier. search in the rest of non-created property-groups
            set organizations [$manifest selectNodes "*\[local-name()='organizations'\]"]

            set property_groups [$organizations selectNodes {*[local-name()='learning-design']/*[local-name()='components']/*[local-name()='porperties']/*[local-name()='property-group' ] } ]
#                set property_groups [[[[$organizations child all imsld:learning-design] child all imsld:components] child all imsld:property] child all imsld:property-group]
            
            set found_p 0
            foreach referenced_property_group $property_groups {
                set referenced_identifier [imsld::parse::get_attribute -node $referenced_property_group -attr_name identifier]
                if { [string eq $ref $referenced_identifier] } {
                    set found_p 1
                    set referenced_property_group_node $referenced_property_group
                }
            }
            if { $found_p } {
                # ok, let's create the property group
                set property_group_ref_list [imsld::parse::parse_and_create_property_group -property_group_node $referenced_property_group_node \
                                                     -component_id $component_id \
                                                     -manifest_id $manifest_id \
                                                     -manifest $manifest \
                                                     -parent_id $parent_id \
                                                     -tmp_dir $tmp_dir]
                
                set property_group_ref_id [lindex $property_group_ref_list 0]
                if { !$property_group_ref_list } {
                    # there is an error, abort and return the list with the error
                    return $property_group_ref_list
                }
                # finally, do the mappings
                relation_add imsld_gprop_gprop_rel $property_group_id $property_group_ref_id
            } else {
                # error
                return [list 0 "[_ imsld.lt_There_is_no_property-]"]
            }
        } else {
            # do the mappings
            relation_add imsld_gprop_prop_rel $property_group_id $property_item_id
        }
    }
    return $property_group_id
}

ad_proc -public imsld::parse::parse_and_create_property { 
    -component_id
    -manifest
    -manifest_id
    -property_node
    -parent_id
    -tmp_dir
} {
    Parse IMS-LD property and stores all the information in the database.

    Returns a list with the new property_id (item_id) created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param role_type staff or learner
    @param component_id Component identifier which this role belongs to
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param roles_node The role node to parse 
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
    @option parent_role_id Parent role identifier. Default to null
} {
    upvar files_struct_list files_struct_list
    set property_id ""
    set property_group_id ""

    # loc properties
    set loc_properties [$property_node selectNodes "*\[local-name()='loc-property' \]"]
    foreach loc_property $loc_properties {
        set lp_title [imsld::parse::get_title -node $loc_property -prefix imsld]
        set lp_identifier [imsld::parse::get_attribute -node $loc_property -attr_name identifier]
        set lp_datatype [$loc_property selectNodes "*\[local-name()='datatype' \]"] 
        imsld::parse::validate_multiplicity -tree $lp_datatype -multiplicity 1 -element_name "loc-property datatype" -equal
        set lp_datatype [string tolower [imsld::parse::get_attribute -node $lp_datatype -attr_name datatype]]
        set lp_initial_value [$loc_property selectNodes "*\[local-name()='initial-value' \]"] 
        imsld::parse::validate_multiplicity -tree $lp_initial_value -multiplicity 1 -element_name "loc-property initial-value" -lower_than
        if { [llength $lp_initial_value] } {
            set lp_initial_value [imsld::parse::get_element_text -node $lp_initial_value]
        } else {
            set lp_initial_value ""
        }

        set property_id [imsld::item_revision_new -attributes [list [list component_id $component_id] \
                                                                      [list identifier $lp_identifier] \
                                                                      [list type loc] \
                                                                      [list datatype $lp_datatype] \
                                                                      [list initial_value $lp_initial_value]] \
                                -content_type imsld_property \
                                -title $lp_title \
                                -parent_id $parent_id]

        set lp_restrictions [$loc_property selectNodes "*\[local-name()='restriction' \]"]
        foreach lp_restriction $lp_restrictions {
            set restriction_list [imsld::parse::parse_and_create_restriction -manifest $manifest \
                                      -property_id $property_id \
                                      -manifest_id $manifest_id \
                                      -restriction_node $lp_restriction \
                                      -parent_id $parent_id \
                                      -tmp_dir $tmp_dir]
            
            set restriction_id [lindex $restriction_list 0]
            if { !$restriction_id } {
                # an error happened, abort and return the list whit the error
                return $restriction_list
            }
        }
    }

    # locpers properties
    set locpers_properties [$property_node selectNodes "*\[local-name()='locpers-property' \]"]
    foreach locpers_property $locpers_properties {
        set lpp_title [imsld::parse::get_title -node $locpers_property -prefix imsld]
        set lpp_identifier [imsld::parse::get_attribute -node $locpers_property -attr_name identifier]
        set lpp_datatype [$locpers_property selectNodes "*\[local-name()='datatype' \]"] 
        imsld::parse::validate_multiplicity -tree $lpp_datatype -multiplicity 1 -element_name "locpers-property datatype" -equal
        set lpp_datatype [string tolower [imsld::parse::get_attribute -node $lpp_datatype -attr_name datatype]]
        set lpp_initial_value [$locpers_property selectNodes "*\[local-name()='initial-value' \]"] 
        imsld::parse::validate_multiplicity -tree $lpp_initial_value -multiplicity 1 -element_name "locpers-property initial-value" -lower_than
        if { [llength $lpp_initial_value] } {
            set lpp_initial_value [imsld::parse::get_element_text -node $lpp_initial_value]
        } else {
            set lpp_initial_value ""
        }

        set property_id [imsld::item_revision_new -attributes [list [list component_id $component_id] \
                                                                       [list identifier $lpp_identifier] \
                                                                       [list type locpers] \
                                                                       [list datatype $lpp_datatype] \
                                                                       [list initial_value $lpp_initial_value]] \
                                 -content_type imsld_property \
                                 -title $lpp_title \
                                 -parent_id $parent_id]
        
        set lpp_restrictions [$locpers_property selectNodes "*\[local-name()='restriction'\]"]
        foreach lpp_restriction $lpp_restrictions {
            set restriction_list [imsld::parse::parse_and_create_restriction -manifest $manifest \
                                      -property_id $property_id \
                                      -manifest_id $manifest_id \
                                      -restriction_node $lpp_restriction \
                                      -parent_id $parent_id \
                                      -tmp_dir $tmp_dir]
            
            set restriction_id [lindex $restriction_list 0]
            if { !$restriction_id } {
                # an error happened, abort and return the list whit the error
                return $restriction_list
            }
        }
    }

    # locrole properties
    set locrole_properties [$property_node selectNodes "*\[local-name()='locrole-property'\]"]
    foreach locrole_property $locrole_properties {
        set lrp_title [imsld::parse::get_title -node $locrole_property -prefix imsld]
        set lrp_identifier [imsld::parse::get_attribute -node $locrole_property -attr_name identifier]
        set lrp_datatype [$locrole_property selectNodes "*\[local-name()='datatype'\]"] 
        imsld::parse::validate_multiplicity -tree $lrp_datatype -multiplicity 1 -element_name "locrole-property datatype" -equal
        set lrp_datatype [string tolower [imsld::parse::get_attribute -node $lrp_datatype -attr_name datatype]]

        set role_ref [$lrp_datatype selectNodes "*\[local-name()='role-ref'\]"]
        imsld::parse::validate_multiplicity -tree $lrp_datatype -multiplicity 1 -element_name "locrole-property role" -equal
        set ref [imsld::parse::get_attribute -node $role_ref -attr_name ref]
        if { ![db_0or1row get_role_id {
            select item_id as role_id 
            from imsld_rolesi 
            where identifier = :ref 
            and content_revision__is_live(role_id) = 't' 
            and component_id = :component_id
        }] } {
            # there is no role with that identifier, return the error
            return [list 0 "[_ imsld.lt_There_is_no_role_with_6]"]
        }

        set lrp_initial_value [$locrole_property selectNodes "*\[local-name()='initial-value'\]"] 
        imsld::parse::validate_multiplicity -tree $lrp_initial_value -multiplicity 1 -element_name "locrole-property initial-value" -lower_than
        if { [llength $lrp_initial_value] } {
            set lrp_initial_value [imsld::parse::get_element_text -node $lrp_initial_value]
        } else {
            set lrp_initial_value ""
        }

        set property_id [imsld::item_revision_new -attributes [list [list component_id $component_id] \
                                                                       [list identifier $lrp_identifier] \
                                                                       [list type locrole] \
                                                                       [list datatype $lrp_datatype] \
                                                                       [list role_id $role_id] \
                                                                       [list initial_value $lrp_initial_value]] \
                                 -content_type imsld_property \
                                 -title $lrp_title \
                                 -parent_id $parent_id]
        
        set lrp_restrictions [$locrole_property selectNodes "*\[local-name()='restriction'\]"]
        foreach lrp_restriction $lrp_restrictions {
            set restriction_list [imsld::parse::parse_and_create_restriction -manifest $manifest \
                                      -property_id $property_id \
                                      -manifest_id $manifest_id \
                                      -restriction_node $lrp_restriction \
                                      -parent_id $parent_id \
                                      -tmp_dir $tmp_dir]
            
            set restriction_id [lindex $restriction_list 0]
            if { !$restriction_id } {
                # an error happened, abort and return the list whit the error
                return $restriction_list
            }
        }
    }

    # globpers properties
    set globpers_properties [$property_node selectNodes "*\[local-name()='globpers-property'\]"]
    foreach globpers_property $globpers_properties {
        set gp_identifier [imsld::parse::get_attribute -node $globpers_property -attr_name identifier]
        set gp_existing [$globpers_property selectNodes "*\[local-name()='existing'\]"] 
        imsld::parse::validate_multiplicity -tree $gp_existing -multiplicity 1 -element_name "existing(globpers)" -lower_than
        if { [llength $gp_existing] } {
            set gp_existing_href [imsld::parse::get_attribute -node $gp_existing -attr_name href]
        } else {
            set gp_existing_href ""
        }

        set global_def [$globpers_property selectNodes "*\[local-name()='global-definition'\]"]
        if { ![empty_string_p $global_def] } {
            imsld::parse::validate_multiplicity -tree $global_def -multiplicity 1 -element_name "global-definition(globpers)" -equal
        }
        set global_def_list [imsld::parse::parse_and_create_global_def -type globpers \
                                 -identifier $gp_identifier \
                                 -existing_href $gp_existing_href \
                                 -global_def_node $global_def \
                                 -component_id $component_id \
                                 -manifest $manifest \
                                 -manifest_id $manifest_id \
                                 -parent_id $parent_id \
                                 -tmp_dir $tmp_dir]
        
        set property_id [lindex $global_def_list 0]
        if { !$property_id } {
            # an error happened, abort and return the list whit the error
            return $global_def_list
        }
    }

    # globp properties
    set glob_properties [$property_node selectNodes "*\[local-name()='glob-property'\]"]
    foreach glob_property $glob_properties {
        set g_identifier [imsld::parse::get_attribute -node $glob_property -attr_name identifier]
        set g_existing [$glob_property selectNodes "*\[local-name()='existing'\]"] 
        imsld::parse::validate_multiplicity -tree $g_exiting -multiplicity 1 -element_name "existing(glob)" -lower_than
        if { [llength $g_existing] } {
            set g_existing_href [imsld::parse::get_attribute -node $g_exiting -attr_name href]
        } else {
            set g_existing_href ""
        }

        set global_def [$glob_property selectNodes "*\[local-name()='global-definition'\]"]
        set global_def_list [imsld::parse::parse_and_create_global_def -type glob \
                                 -identifier $g_identifier \
                                 -existing_href $g_existing_href \
                                 -global_def_node $global_def \
                                 -component_id $component_id \
                                 -manifest $manifest \
                                 -manifest_id $manifest_id \
                                 -parent_id $parent_id \
                                 -tmp_dir $tmp_dir]
        set property_id [lindex $global_def_list 0]
        if { !$property_id } {
            # an error happened, abort and return the list whit the error
            return $global_def_list
        }
    }

    # property groups
    set property_groups [$property_node selectNodes "*\[local-name()='property-group'\]"]
    foreach property_group $property_groups {
        set property_group_list [imsld::parse::parse_and_create_property_group -property_group_node $property_group \
                                     -component_id $component_id \
                                     -manifest $manifest \
                                     -manifest_id $manifest_id \
                                     -parent_id $parent_id \
                                     -tmp_dir $tmp_dir]
        set property_group_id [lindex $property_group_list 0]
        if { !$property_group_id } {
            # an error happened, abort and return the list whit the error
            return $property_group_list
        }
    }
    return [expr { [string eq $property_id ""] ? $property_group_id : $property_id }]
}

ad_proc -public imsld::parse::parse_and_create_learning_objective { 
    -learning_objective_node
    -manifest:required
    -manifest_id:required
    -parent_id:required
    -tmp_dir:required
} {
    Parse a learning objective and stores all the information in the database.

    Returns a list with the new learning_objective_id (item_id) created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param learning_objective_node learning objective node to parse
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @option activity_name In case the learning objective forms part of an activity, the name is provided to be used as the pretty name of the possible associated objects
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
} {
    upvar files_struct_list files_struct_list

    # get learning objective info
    set learning_objective_title [imsld::parse::get_title -node $learning_objective_node -prefix imsld]
    set learning_objective_id [imsld::item_revision_new -title $learning_objective_title \
                                   -content_type imsld_learning_objective \
                                   -parent_id $parent_id \
                                   -attributes [list [list pretty_title $learning_objective_title]]]
                                                
    # learning objective: imsld_items
    set learning_objective_items [$learning_objective_node selectNodes "*\[local-name()='item'\]"]
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

    Returns a list with the new prerequisite_id (item_id) created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param prerequisite_node prerequisite node to parse
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
} {
    upvar files_struct_list files_struct_list

    # get prerequisite info
    set prerequisite_title [imsld::parse::get_title -node $prerequisite_node -prefix imsld]
    set prerequisite_id [imsld::item_revision_new -title $prerequisite_title \
                             -content_type imsld_prerequisite \
                             -parent_id $parent_id \
                             -attributes [list [list pretty_title $prerequisite_title]]]
    
    # prerequisite: imsld_items
    set prerequisite_items [$prerequisite_node selectNodes "*\[local-name()='item'\]"]
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
            relation_add imsld_preq_item_rel $prerequisite_id $item_id
        } 
    }
    return $prerequisite_id
}

ad_proc -public imsld::parse::parse_and_create_activity_description { 
    -activity_description_node
    -manifest
    -manifest_id
    {-activity_name ""}
    -parent_id
    -tmp_dir
} {
    Parse a activity description and stores all the information in the database.

    Returns a list with the new activity_description_id (item_id) created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param activity_description_node activity description node to parse
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @option activity_name Provided to name the possible objects associated with the activity
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
} {
    upvar files_struct_list files_struct_list

    # get activity description info
    set activity_description_title [imsld::parse::get_title -node $activity_description_node -prefix imsld]
    set activity_description_id [imsld::item_revision_new -title $activity_description_title \
                                     -content_type imsld_activity_desc \
                                     -parent_id $parent_id]
    
    # activity description: imsld_items
    set activity_description_items [$activity_description_node selectNodes "*\[local-name()='item'\]"]
    if { [llength $activity_description_items] } {
        foreach imsld_item $activity_description_items {
            
            set item_list [imsld::parse::parse_and_create_item -manifest $manifest \
                               -manifest_id $manifest_id \
                               -item_node $imsld_item \
                               -activity_name $activity_name \
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
    -environment_id:required
    -manifest
    -manifest_id
    -parent_id
    -tmp_dir
} {
    Parse a learning object and stores all the information in the database.

    Returns a list with the new learning_object_id (item_id) created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param learning_object_node learning object node to parse
    @param environment_id environment ID of the one tha owns the learning objective
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
} {
    upvar files_struct_list files_struct_list

    # get learning object info
    set learning_object_class [imsld::parse::get_attribute -node $learning_object_node -attr_name class]
    set identifier [imsld::parse::get_attribute -node $learning_object_node -attr_name identifier]
    set is_visible_p [imsld::parse::get_bool_attribute -node $learning_object_node -attr_name isvisible -default t]
    set parameters [imsld::parse::get_attribute -node $learning_object_node -attr_name parameters]
    set type [imsld::parse::get_attribute -node $learning_object_node -attr_name type]
    set title [imsld::parse::get_title -node $learning_object_node -prefix imsld]

    set learning_object_id [imsld::item_revision_new -attributes [list [list class $learning_object_class] \
                                                                      [list identifier $identifier] \
                                                                      [list is_visible_p $is_visible_p] \
                                                                      [list parameters $parameters] \
                                                                      [list type $type] \
                                                                      [list environment_id $environment_id]] \
                                -content_type imsld_learning_object \
                                -title $title \
                                -parent_id $parent_id]

    # learning object: imsld_items
    set learning_object_items [$learning_object_node selectNodes "*\[local-name()='item'\]"]
    foreach learning_object_item $learning_object_items {
        set item_list [imsld::parse::parse_and_create_item -manifest $manifest \
                           -manifest_id $manifest_id \
                           -item_node $learning_object_item \
                           -parent_id $parent_id \
                           -tmp_dir $tmp_dir]
        
        set item_id [lindex $item_list 0]
        if { !$item_id } {
            # an error happened, abort and return the list whit the error
            return $item_list
        }
        # map item with the learning_object
        relation_add imsld_l_object_item_rel $learning_object_id $item_id
    } 
    return $learning_object_id
}

ad_proc -public imsld::parse::parse_and_create_forum { 
    -name
} {
    Create a forum with the given name.

    @param name Forum's name
} {
    
    set community_id [dotlrn_community::get_community_id]
    set forums_package_id [site_node_apm_integration::get_child_package_id \
                               -package_id [dotlrn_community::get_package_id $community_id] \
                               -package_key "forums"]
    set acs_object_id [forum::new -name $name -package_id $forums_package_id]
    #revoke read permissions until first usage
    if {[info exist acs_object_id]} {
        permission::set_not_inherit -object_id $acs_object_id
        set party_id [db_list get_allowed_parties {}]
        foreach parti $party_id {
            permission::revoke -party_id $parti -object_id $acs_object_id -privilege "read"
        }
    }
    return $acs_object_id
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

    Returns a list with the new service_ids (item_ids) created if there were no errors, or 0 and an explanation messge if there was an error. The service element can have conference or send-mail services (index service is currently not supported in .LRN), and they are created directly as a service, i.e. there is no table for storing the services, they are stored directly in the send-mail or conference tables.
    
    @param service_node service node to parse
    @param environment_id
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
} {
    upvar files_struct_list files_struct_list

    # get service info
    set service_class [imsld::parse::get_attribute -node $service_node -attr_name class]
    set identifier [imsld::parse::get_attribute -node $service_node -attr_name identifier]
    set is_visible_p [imsld::parse::get_bool_attribute -node $service_node -attr_name isvisible -default t]
    set parameters [imsld::parse::get_attribute -node $service_node -attr_name parameters]
    
    set component_id [db_string get_component_id {
        select env.component_id
        from imsld_environmentsi env
        where content_revision__is_live(env.environment_id) = 't'
        and env.item_id = :environment_id
    }]

    # send mail
    set send_mail [$service_node selectNodes "*\[local-name()='send-mail'\]"]
    if { [llength $send_mail] } {
        # it's a send mail service, get the info and create the service
        imsld::parse::validate_multiplicity -tree $send_mail -multiplicity 1 -element_name send-mail -equal
        set select [imsld::parse::get_attribute -node $send_mail -attr_name select]
        expr { [string eq [string tolower $select] all-persons-in-role] ? [set recipients all-in-role] : [set recipients selection] }
        set title [imsld::parse::get_title -node $send_mail -prefix imsld]
        # create the service
        set service_id [imsld::item_revision_new -attributes [list [list environment_id $environment_id] \
                                                                  [list class $service_class] \
                                                                  [list identifier $identifier] \
                                                                  [list is_visible_p $is_visible_p] \
                                                                  [list parameters $parameters] \
                                                                  [list service_type send-mail]] \
                            -content_type imsld_service \
                            -parent_id $parent_id]
        # create the send mail service
        set send_mail_id [imsld::item_revision_new -attributes [list [list service_id $service_id] \
                                                                    [list is_visible_p $is_visible_p] \
                                                                    [list parameters $parameters] \
                                                                    [list recipients $recipients]] \
                              -parent_id $parent_id \
                              -content_type imsld_send_mail_service \
                              -title $title]

        set email_data_list [$send_mail selectNodes "*\[local-name()='email-data'\]"]
        imsld::parse::validate_multiplicity -tree $email_data_list -multiplicity 1 -element_name email-data -greather_than
        foreach email_data $email_data_list {
            set role_ref [$email_data selectNodes "*\[local-name()='role-ref'\]"]
            imsld::parse::validate_multiplicity -tree $role_ref -multiplicity 1 -element_name role-ref(email-data) -equal
            set ref [imsld::parse::get_attribute -node $role_ref -attr_name ref]
            if { ![db_0or1row get_role_id_from_ref {
                select ir.item_id as role_id
                from imsld_rolesi ir
                where ir.identifier = :ref 
                and content_revision__is_live(ir.role_id) = 't' 
                and ir.component_id = :component_id
            }] } {
                # there is no role with that identifier, return the error
                return [list 0 "[_ imsld.lt_There_is_no_role_with]"]
            }

            # email-property-ref
            set email_property_ref [imsld::parse::get_attribute -node $email_data -attr_name email-property-ref]
            if { ![string eq $email_property_ref ""] } {
                if { ![db_0or1row get_property_id {
                    select item_id as email_property_id
                    from imsld_propertiesi 
                    where identifier = :email_property_ref
                    and content_revision__is_live(property_id) = 't' 
                    and component_id = :component_id }] } {
                    # there is no property with that identifier, return the error
                    return [list 0 "[_ imsld.lt_There_is_no_property__1]"]
                } 
            } else {
                set email_property_id ""
            }

            # username-property-ref
            set username_property_ref [imsld::parse::get_attribute -node $email_data -attr_name username-property-ref]
            if { ![string eq $username_property_ref ""] } {
                if { ![db_0or1row get_property_id {
                    select item_id as username_property_id
                    from imsld_propertiesi 
                    where identifier = :username_property_ref
                    and content_revision__is_live(property_id) = 't' 
                    and component_id = :component_id }] } {
                    # there is no property with that identifier, return the error
                    return [list 0 "[_ imsld.lt_There_is_no_property__2]"]
                }
            } else {
                set username_property_id ""
            }

            set email_data_id [imsld::item_revision_new -attributes [list [list role_id $role_id] \
                                                                         [list mail_data {}] \
                                                                         [list email_property_id $email_property_id] \
                                                                         [list username_property_id $username_property_id]] \
                                   -content_type imsld_send_mail_data \
                                   -parent_id $parent_id]
            # map email_data with the service
            relation_add imsld_send_mail_serv_data_rel $send_mail_id $email_data_id
        }
    }

    # conferences
    set conference [$service_node selectNodes "*\[local-name()='conference'\]"]
    if { [llength $conference] } {
        # it's a conference service, get the info an create the service
        imsld::parse::validate_multiplicity -tree $conference -multiplicity 1 -element_name conference -equal
        set conference_type [string tolower [imsld::parse::get_attribute -node $conference -attr_name conference-type]]
        set title [imsld::parse::get_title -node $conference -prefix imsld]
        
        # manager
        set manager [$conference selectNodes "*\[local-name()='conference-manager'\]"]
        set manager_id ""
        if { [llength $manager] } {
            imsld::parse::validate_multiplicity -tree $manager -multiplicity 1 -element_name conference-manager -equal
            set role_ref [imsld::parse::get_attribute -node $manager -attr_name role-ref]
            if { ![db_0or1row get_role_id_from_role_ref {
                select item_id as manager_id 
                from imsld_rolesi 
                where identifier = :role_ref 
                and content_revision__is_live(role_id) = 't' 
                and component_id = :component_id }] } {
                # there is no role with that identifier, return the error
                return [list 0 "[_ imsld.lt_There_is_no_role_with_1]"]
            } else {
                set manager_id $role_item_id
            }
        }

        # create the service
        set service_id [imsld::item_revision_new -attributes [list [list environment_id $environment_id] \
                                                                  [list class $service_class] \
                                                                  [list identifier $identifier] \
                                                                  [list is_visible_p $is_visible_p] \
                                                                  [list parameters $parameters] \
                                                                  [list service_type conference]] \
                            -content_type imsld_service \
                            -parent_id $parent_id]
        
        if { [string eq $conference_type "asynchronous"] } {
            set acs_object_id [imsld::parse::parse_and_create_forum -name $title]            
            set resource_id [imsld::cp::resource_new -manifest_id $manifest_id \
                                 -identifier "forumresource-$service_id" \
                                 -type "forum" \
                                 -href "" \
                                 -acs_object_id $acs_object_id \
                                 -parent_id $parent_id]
            
            set imsld_item_id [imsld::item_revision_new -title $title \
                                   -content_type imsld_item \
                                   -attributes [list [list identifier "forumitem-$service_id"] \
                                                    [list is_visible_p "t"] \
                                                    [list parameters ""] \
                                                    [list identifierref "forumresource-$service_id"] \
                                                    [list parent_item_id {}]] \
                                   -parent_id $parent_id]
            
            # map item with resource
            relation_add imsld_item_res_rel $imsld_item_id $resource_id

        } else {
            # item
            set conference_item [$conference selectNodes "*\[local-name()='item'\]"]
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
	
        }
        
        # moderator
        set moderator_id ""
        set moderator_list [$conference selectNodes "*\[local-name()='moderator'\]"]
        if { [llength $moderator_list] } {
            foreach moderator $moderator_list {
                set role_ref [imsld::parse::get_attribute -node $moderator -attr_name role-ref]
                if { ![db_0or1row get_role_id_from_role_ref {
                    select item_id as moderator_id 
                    from imsld_rolesi 
                    where identifier = :role_ref 
                    and content_revision__is_live(role_id) = 't' 
                    and component_id = :component_id 
                }] } {
                    # there is no role with that identifier, return the error
                    return [list 0 "[_ imsld.lt_There_is_no_role_with_4]"]
                } else {
                    set moderator_id $role_item_id
                }
            }
        }

        # create the conference service
        set conference_id [imsld::item_revision_new -attributes [list [list service_id $service_id] \
                                                                          [list manager_id $manager_id] \
                                                                          [list moderator_id $moderator_id] \
                                                                          [list conference_type $conference_type] \
                                                                          [list imsld_item_id $imsld_item_id]] \
                               -content_type imsld_conference_service \
                               -parent_id $parent_id \
                               -title $title]

        # participants
        set participant_list [$conference selectNodes "*\[local-name()='participant'\]"]
        imsld::parse::validate_multiplicity -tree $participant_list -multiplicity 1 -element_name conference-participant -greather_than
        foreach participant $participant_list {
            set role_ref [imsld::parse::get_attribute -node $participant -attr_name role-ref]
            if { ![db_0or1row get_role_id_from_role_ref {
                select item_id as participant_id 
                from imsld_rolesi 
                where identifier = :role_ref 
                and content_revision__is_live(role_id) = 't' 
                and component_id = :component_id
            }] } {
                # there is no role with that identifier, return the error
                return [list 0 "[_ imsld.lt_There_is_no_role_with_2]"]
            } else {
                set participant_id $role_item_id
            }
            # map conference with participant role
            relation_add imsld_conf_part_rel $conference_id $participant_id
        }

        # observer
        set observer_list [$conference selectNodes "*\[local-name()='observer'\]"]
        if { [llength $observer_list] } {
            foreach observer $observer_list {
                set role_ref [imsld::parse::get_attribute -node $observer -attr_name role-ref]
                if { ![db_0or1row get_role_id_from_role_ref {
                    select item_id as observer_id 
                    from imsld_rolesi 
                    where identifier = :role_ref 
                    and content_revision__is_live(role_id) = 't' 
                    and component_id = :component_id 
                }] } {
                    # there is no role with that identifier, return the error
                    return [list 0 "[_ imsld.lt_There_is_no_role_with_3]"]
                } else {
                    set observer_id $role_item_id
                }
                # map conference with observer role
                relation_add imsld_conf_obser_rel $conference_id $observer_id
            }
        }

                
    }
    
    # index service (not supported)
    set index_search [$service_node selectNodes "*\[local-name()='index-search'\]"]
    if { [llength $index_search] } {
        ns_log error "Index-search service not supported"
        return [list 0 "[_ imsld.lt_Index_search_service_]"]
    }
    
    # monitor service (level b)
    set monitor_service [$service_node selectNodes "*\[local-name()='monitor'\]"]
    if { [llength $monitor_service] } {
        imsld::parse::validate_multiplicity -tree $monitor_service -multiplicity 1 -element_name monitor-service -equal
        set title [imsld::parse::get_title -node $monitor_service -prefix imsld]
        # create the service
        set service_id [imsld::item_revision_new -attributes [list [list environment_id $environment_id] \
                                                                  [list class $service_class] \
                                                                  [list identifier $identifier] \
                                                                  [list is_visible_p $is_visible_p] \
                                                                  [list parameters $parameters] \
                                                                  [list service_type monitor]] \
                            -title $title \
                            -content_type imsld_service \
                            -parent_id $parent_id]

        # monitor: role-ref
        set role_ref [$monitor_service selectNodes "*\[local-name()='role-ref'\]"]
        imsld::parse::validate_multiplicity -tree $role_ref -multiplicity 1 -element_name "role-ref (monitor service)" -equal
        set ref [imsld::parse::get_attribute -node $role_ref -attr_name ref]
        if { ![db_0or1row get_role_id {
            select ir.item_id as role_id
            from imsld_rolesi ir
            where ir.identifier = :ref 
            and content_revision__is_live(ir.role_id) = 't' 
            and ir.component_id = :component_id
        }] } {
            # there is no role with that identifier, return the error
            return [list 0 "[_ imsld.lt_There_is_no_role_with_7]"]
        }
        
        # monitor: self
        set self [$monitor_service selectNodes "*\[local-name()='self'\]"]
        if { [llength [$monitor_service selectNodes "*\[local-name()='self'\]"]] } {
            imsld::parse::validate_multiplicity -tree $self -multiplicity 1 -element_name self -equal
            set self_p t
        } else {
            set self_p f
        }
        
        set imsld_item [$monitor_service selectNodes "*\[local-name()='item'\]"]
        imsld::parse::validate_multiplicity -tree $imsld_item -multiplicity 1 -element_name "imslditem(monitor service)" -equal
        set item_list [imsld::parse::parse_and_create_item -manifest $manifest \
                           -manifest_id $manifest_id \
                           -item_node $imsld_item \
                           -parent_id $parent_id \
                           -tmp_dir $tmp_dir]
        
        set imsld_item_id [lindex $item_list 0]
        if { !$imsld_item_id } {
            # an error happened, abort and return the list whit the error
            return $item_list
        }
    
        # create the monitor service
        set monitor_service_id [imsld::item_revision_new -attributes [list [list service_id $service_id] \
                                                                    [list role_id $role_id] \
                                                                    [list self_p $self_p] \
                                                                    [list imsld_item_id $imsld_item_id]] \
                              -parent_id $parent_id \
                              -content_type imsld_monitor_service \
                              -title $title]
    }
    
    return $service_id
}

ad_proc -public imsld::parse::parse_and_create_environment { 
    -component_id:required
    -environment_node
    -manifest
    -manifest_id
    -parent_id
    -tmp_dir
} {
    Parse a environment and stores all the information in the database.

    Returns a list with the new environment_id (item_id) created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param environment_node environment node to parse
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
} {
    upvar files_struct_list files_struct_list
    upvar warnings warnings

    # get environment info
    set identifier [imsld::parse::get_attribute -node $environment_node -attr_name identifier]
    set title [imsld::parse::get_title -node $environment_node -prefix imsld]
    
    # check if the environmet hasn't been already created by the reference of another environment previously parsed
    if { [db_0or1row already_created_environment {
        select item_id as environment_item_id
        from imsld_environmentsi
        where identifier = :identifier
        and component_id = :component_id
        and content_revision__is_live(environment_id) = 't'
    }]} {
        return $environment_item_id
    }
    # create the environment 
    set environment_id [imsld::item_revision_new -attributes [list [list component_id $component_id] \
                                                                [list identifier $identifier]] \
                            -content_type imsld_environment \
                            -title $title \
                            -parent_id $parent_id]

    # environment: learning object
    set learning_objects [$environment_node selectNodes "*\[local-name()='learning-object'\]"]
    foreach learning_object $learning_objects {
        set learning_object_list [imsld::parse::parse_and_create_learning_object -learning_object_node $learning_object \
                                      -environment_id $environment_id \
                                      -manifest_id $manifest_id \
                                      -manifest $manifest \
                                      -parent_id $parent_id \
                                      -tmp_dir $tmp_dir]
        
        set learning_object_id [lindex $learning_object_list 0]
        if { !$learning_object_id } {
            # there is an error, abort and return the list with the error
            return $learning_object_list
        }
    }

    # environment: service
    set services [$environment_node selectNodes "*\[local-name()='service'\]"]
    foreach service $services {
        set service_list [imsld::parse::parse_and_create_service -service_node $service \
                              -environment_id $environment_id \
                              -manifest_id $manifest_id \
                              -manifest $manifest \
                              -parent_id $parent_id \
                              -tmp_dir $tmp_dir]
        if { ![lindex $service_list 0] } {
            # there is an error, abort and return the list with the error
            return $service_list
        }
    }

    # environment: environment ref
    set environment_ref_list [$environment_node selectNodes "*\[local-name()='environment-ref'\]"]
    if { [llength $environment_ref_list] } {
        foreach environment_ref $environment_ref_list {
            set ref [imsld::parse::get_attribute -node $environment_ref -attr_name ref]
            # we have to search for the referenced environment and there are two cases:
            # 1. the referenced environment has been created: get the id from the database and do the mappings
            # 2. the referenced environment hasn't been created: invoke the parse_and_create_environment proc,
            #    but first verify that the environment exists in the manifest
            if { [db_0or1row get_env_id {
                select item_id as refrenced_env_id 
                from imsld_environmentsi 
                where identifier = :ref 
                and content_revision__is_live(environment_id) = 't' 
                and component_id = :component_id
            }] } {
                # case one, just do the mappings
                relation_add imsld_env_env_rel $environment_id $refrenced_env_id
            } else {
                # case two, first verify that the referenced environment exists
                set organizations [$manifest selectNodes "*\[local-name()='organizations'\]"]
                set environments [$organizations selectNodes {*[local-name()='learning-design']/*[local-name()='components']/*[local-name()='environments']}]
#                set environments [[[$organizations child all imsld:learning-design] child all imsld:components] child all imsld:environments]
                set found_p 0
                foreach referenced_environment [$environments selectNodes "*\[local-name()='environment'\]"] {
                    set referenced_identifier [imsld::parse::get_attribute -node $referenced_environment -attr_name identifier]
                    if { [string eq $ref $referenced_identifier] } {
                        set found_p 1
                        set environment_referenced_node $referenced_environment
                    }
                }
                if { $found_p } {
                        # ok, let's create the environment
                    set environment_ref_list [imsld::parse::parse_and_create_environment -environment_node $environment_referenced_node \
                                                  -manifest_id $manifest_id \
                                                  -manifest $manifest \
                                                  -parent_id $parent_id \
                                                  -component_id $component_id \
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
                    return [list 0 "[_ imsld.lt_Referenced_environmen]"]
                }
            }
        }
    }
    return $environment_id
}

ad_proc -public imsld::parse::parse_and_create_property_value { 
    -property_value_node
    -manifest
    -manifest_id
    -parent_id
} {
    Parse a property value and stores all the information in the database.

    Returns a list with the new property_value_id (item_id) created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param component_id Component identifier which this role belongs to
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param activity_node The activity node to parse 
    @param parent_id Parent folder ID
} {
    # Property Ref
    set property_ref [$property_value_node selectNodes "*\[local-name()='property-ref'\]"]
    imsld::parse::validate_multiplicity -tree $property_ref -multiplicity 1 -element_name property-ref(property-value) -equal
    set ref [imsld::parse::get_attribute -node $property_ref -attr_name ref]
    if { ![db_0or1row get_property_id {
        select ip.item_id as property_id 
        from imsld_propertiesi ip, imsld_componentsi ic, imsld_imsldsi ii, imsld_cp_organizationsi ico
        where ip.identifier = :ref 
        and content_revision__is_live(property_id) = 't' 
        and ip.component_id = ic.item_id
        and ic.imsld_id = ii.item_id
        and ii.organization_id = ico.item_id
        and ico.manifest_id = :manifest_id
    }] } {
        # there is no property with that identifier, return the error
        return [list 0 "[_ imsld.lt_There_is_no_property__3]"]
    }

    set langstring ""
    set calculate ""
    set expression_xml ""
    
    # Property Value
    set property_value [$property_value_node selectNodes "*\[local-name()='property-value'\]"]
    if { [llength $property_value] } {
        imsld::parse::validate_multiplicity -tree $property_value -multiplicity 1 -element_name property-value(property-value) -equal
        
        # Langstring
        set langstring [$property_value_node selectNodes "*\[local-name()='langstring'\]"]
        if { [llength $langstring] } {
            imsld::parse::validate_multiplicity -tree $langstring -multiplicity 1 -element_name langstring(property-value) -equal
            set langstring [imsld::parse::get_element_text -node $langstring]
        } elseif { ![string eq "" [imsld::parse::get_element_text -node $property_value]] } {
            set langstring [imsld::parse::get_element_text -node $property_value]
        } 
        
        # Calculate
        set calculate [$property_value_node selectNodes "*\[local-name()='calculate'\]"]
        if { [llength $calculate] } {
            imsld::parse::validate_multiplicity -tree $calculate -multiplicity 1 -element_name calculate(property-value) -equal

            set temporal_doc [dom createDocument calculate]
            set temporal_node [$temporal_doc documentElement]

            # Expression
            set expression [$calculate childNodes]
            imsld::parse::validate_multiplicity -tree $expression -multiplicity 1 -element_name expression(property-value) -equal
            $temporal_node appendChild $expression

            set expression_xml [$temporal_node asXML]
        }
    }

    set property_value_id [imsld::item_revision_new -attributes [list [list property_id $property_id] \
                                                                     [list langstring $langstring] \
                                                                     [list expression_xml $expression_xml] \
                                                                     [list property_value_ref $property_id]] \
                               -content_type imsld_property_value \
                               -parent_id $parent_id]
    return $property_value_id
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

    Returns a list with the new activity_id (item_id) created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param component_id Component identifier which this role belongs to
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param activity_node The activity node to parse 
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
} {
    upvar files_struct_list files_struct_list
    upvar warnings warnings

    # get the info of the learning activity and create it
    set identifier [imsld::parse::get_attribute -node $activity_node -attr_name identifier]
    set is_visible_p [imsld::parse::get_bool_attribute -node $activity_node -attr_name isvisible -default t]
    set parameters [imsld::parse::get_attribute -node $activity_node -attr_name parameters]
    set title [imsld::parse::get_title -node $activity_node -prefix imsld]
    
    # Learning Activity: Learning Objectives (which are really an imsld_item that can have resource associated.)
    set learning_objectives [$activity_node selectNodes "*\[local-name()='learning-objectives'\]"]
    if { [llength $learning_objectives] } {
        imsld::parse::validate_multiplicity -tree $learning_objectives -multiplicity 1 -element_name learning-objectives(learning-activity) -equal
        set learning_objective_list [imsld::parse::parse_and_create_learning_objective -learning_objective_node $learning_objectives \
                                         -manifest_id $manifest_id \
                                         -parent_id $parent_id \
                                         -manifest $manifest \
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
    set prerequisites [$activity_node selectNodes "*\[local-name()='prerequisites'\]"] 
    if { [llength $prerequisites] } {
        imsld::parse::validate_multiplicity -tree $prerequisites -multiplicity 1 -element_name prerequisites(learning-activity) -equal
        set prerequisite_list [imsld::parse::parse_and_create_prerequisite -prerequisite_node $prerequisites \
                                   -manifest_id $manifest_id \
                                   -manifest $manifest \
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

    # Learning Activity: Activity Description
    set activity_description [$activity_node selectNodes "*\[local-name()='activity-description'\]"] 
    imsld::parse::validate_multiplicity -tree $activity_description -multiplicity 1 -element_name activity-description(learning-activity) -equal
    set title [expr { [string eq "" $title] ? "[imsld::parse::get_title -node $activity_description -prefix imsld]" : "$title" }]
    set activity_description_list [imsld::parse::parse_and_create_activity_description -activity_description_node $activity_description \
                                       -manifest_id $manifest_id \
                                       -manifest $manifest \
                                       -activity_name $title \
                                       -parent_id $parent_id \
                                       -tmp_dir $tmp_dir]

    set activity_description_id [lindex $activity_description_list 0]
    if { !$activity_description_id } {
        # there is an error, abort and return the list with the error
        return $activity_description_list
    }

    # Learning Activity: Complete Activity
    # If the learning activity has a "user choice" node, the learner decides when the activity is completed
    # otherwise, the activity ends when "time-limit" is complete.
    # When this element does not occur, the activity is set to 'completed' by default.
    
    set complete_activity [$activity_node selectNodes "*\[local-name()='complete-activity'\]"]
    set user_choice_p f
    set complete_act_id ""
    set time_in_seconds ""
    set when_prop_value_is_set_xml ""
    if { [llength $complete_activity] } {
        imsld::parse::validate_multiplicity -tree $complete_activity -multiplicity 1 -element_name complete-activity(learning-activity) -equal
        
        # Learning Activity: Complete Activity: User Choice
        set user_choice [$complete_activity selectNodes "*\[local-name()='user-choice'\]"]
        if { [llength $user_choice] } {
            imsld::parse::validate_multiplicity -tree $user_choice -multiplicity 1 -element_name user-choice(learning-activity) -equal
            # that's it, the learner decides when the activity is completed
            set user_choice_p t
        }

        # Learning Activity: Complete Activity: Time Limit
        set time_limit [$complete_activity selectNodes "*\[local-name()='time-limit'\]"]
        if { [llength $time_limit] } {
            imsld::parse::validate_multiplicity -tree $time_limit -multiplicity 1 -element_name time-limit(learning-activity) -equal
            set time_string [imsld::parse::get_element_text -node $time_limit]
            set time_in_seconds [imsld::parse::convert_time_to_seconds -time $time_string]
        }

        # Learning Activity: Complete Activity: When Property Value is Set
        set when_prop_value_is_set [$complete_activity selectNodes "*\[local-name()='when-property-value-is-set'\]"] 
        if { [llength $when_prop_value_is_set] } {
            imsld::parse::validate_multiplicity -tree $when_prop_value_is_set -multiplicity 1 -element_name when-property-valye-is-set(learning-activity) -equal
            # create a node where the when-property-value-is-set will be stored
            set temporal_doc [dom createDocument when-property-value-is-set]
            set temporal_node [$temporal_doc documentElement]
            
            $temporal_node appendChild $when_prop_value_is_set
            set when_prop_value_is_set_xml [$temporal_node asXML]
        }
        set complete_act_id [imsld::item_revision_new -attributes [list [list time_in_seconds $time_in_seconds] \
                                                                       [list user_choice_p $user_choice_p] \
                                                                       [list when_prop_val_is_set_xml $when_prop_value_is_set_xml]] \
                                 -content_type imsld_complete_act \
                                 -parent_id $parent_id]

        if { [llength $when_prop_value_is_set] } {
            #search properties in expression 
            set property_nodes_list [$when_prop_value_is_set selectNodes {.//*[local-name()='property-ref']}]
            foreach property $property_nodes_list {
                set property_id [imsld::get_property_item_id -identifier [$property getAttribute ref] -imsld_id [db_string get_imsld_id {select imsld_id from imsld_componentsi where item_id = :component_id}]]
                # map the property with the complete_act_id
                relation_add imsld_prop_wpv_is_rel $property_id $complete_act_id
            }
        }

    }

    # Learning Activity: On Completion
    set on_completion [$activity_node selectNodes "*\[local-name()='on-completion'\]"]
    set on_completion_id ""
    set change_property_value_xml ""
    if { [llength $on_completion] } {
        # Learning Activity: On Completion: Change Property Value
        set change_property_value_list [$on_completion selectNodes "*\[local-name()='change-property-value'\]"] 
        if { [llength $change_property_value_list] } {
            # create a node where all the change-property-values will be stored
            set temporal_doc [dom createDocument change-property-values]
            set temporal_node [$temporal_doc documentElement]
            
            $temporal_node appendChild $change_property_value_list
            set change_property_value_xml [$temporal_node asXML]
        }

        set feedback_desc [$on_completion selectNodes "*\[local-name()='feedback-description'\]"]
        if { [llength $feedback_desc] } {
            imsld::parse::validate_multiplicity -tree $feedback_desc -multiplicity 1 -element_name feedback(learning-activity) -equal
            set feedback_title [imsld::parse::get_title -node $feedback_desc -prefix imsld]
            set on_completion_id [imsld::item_revision_new -parent_id $parent_id \
                                      -content_type imsld_on_completion \
                                      -attributes [list [list feedback_title $feedback_title \
                                                             [list change_property_value_xml $change_property_value_xml]]]]
            set feedback_items [$feedback_desc selectNodes "*\[local-name()='item'\]"]
            foreach feedback_item $feedback_items {
                set item_list [imsld::parse::parse_and_create_item -manifest $manifest \
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
        } else {
            set on_completion_id [imsld::item_revision_new -parent_id $parent_id \
                                      -content_type imsld_on_completion \
                                      -attributes [list [list change_property_value_xml $change_property_value_xml]]]
        }
    }
    # crete learning activity
    set learning_activity_id [imsld::item_revision_new -attributes [list [list identifier $identifier] \
                                                                        [list component_id $component_id] \
                                                                        [list activity_description_id $activity_description_id] \
                                                                        [list parameters $parameters] \
                                                                        [list is_visible_p $is_visible_p] \
                                                                        [list complete_act_id $complete_act_id] \
                                                                        [list on_completion_id $on_completion_id] \
                                                                        [list learning_objective_id $learning_objective_id] \
                                                                        [list prerequisite_id $prerequisite_id]] \
                                  -content_type imsld_learning_activity \
                                  -title $title \
                                  -parent_id $parent_id]

    # to avoid infinite loops, take the notifications parsing out
    if { [llength $on_completion] } {
        # Learning Activity: On Completion: Notifications
        set notifications_list [$on_completion selectNodes "*\[local-name()='notification'\]"] 
        if { [llength $notifications_list] } {
            foreach notification $notifications_list {
                set notification_list [imsld::parse::parse_and_create_notification -component_id $component_id \
                                           -notification_node $notification \
                                           -manifest $manifest \
                                           -manifest_id $manifest_id \
                                           -parent_id $parent_id \
                                           -tmp_dir $tmp_dir]
                set notification_id [lindex $notification_list 0]
                if { !$notification_id } {
                    # an error occurred, return it
                    return $notification_list
                }
                # map on_completion with the notif
                relation_add imsld_on_comp_notif_rel $on_completion_id $notification_id
            }
        }
    }
    
    # Learning Activity: Environments
    set environment_refs [$activity_node selectNodes "*\[local-name()='environment-ref'\]"]
    if { [llength $environment_refs] } {
        foreach environment_ref_node $environment_refs {
            # the environments have been already parsed by now, 
            # so the referenced environment has to be in the database.
            # If not found, return the error
            set environment_ref [imsld::parse::get_attribute -node $environment_ref_node -attr_name ref]
            if { ![db_0or1row get_environment_id {
                select item_id as environment_id
                from imsld_environmentsi
                where identifier = :environment_ref 
                and content_revision__is_live(environment_id) = 't' and 
                component_id = :component_id
            }] } {
                # error, referenced environment does not exist
                return [list 0 "[_ imsld.lt_Referenced_environmen_1]"]
            }

            # map environment with learning-activity
            relation_add imsld_la_env_rel $learning_activity_id $environment_id
        }
    }
    return $learning_activity_id
}

ad_proc -public imsld::parse::parse_and_create_support_activity { 
    -component_id
    -activity_node
    -manifest
    -manifest_id
    -parent_id
    -tmp_dir
} {
    Parse a support activity and stores all the information in the database.

    Returns a list with the new activity_id (item_id) created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param role_type staff or learner
    @param component_id Component identifier which this role belongs to
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param roles_node The role node to parse 
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
    @option parent_role_id Parent role identifier. Default to null
} {
    upvar files_struct_list files_struct_list
    upvar warnings warnings

    # get the info of the support activity and create it
    set identifier [imsld::parse::get_attribute -node $activity_node -attr_name identifier]
    set is_visible_p [imsld::parse::get_bool_attribute -node $activity_node -attr_name isvisible -default t]
    set parameters [imsld::parse::get_attribute -node $activity_node -attr_name parameters]
    set title [imsld::parse::get_title -node $activity_node -prefix imsld]

    # Support Activity: Activity Description
    set activity_description [$activity_node selectNodes "*\[local-name()='activity-description'\]"] 
    imsld::parse::validate_multiplicity -tree $activity_description -multiplicity 1 -element_name activity-description(support-activity) -equal
    set title [expr { [string eq "" $title] ? "[imsld::parse::get_title -node $activity_description -prefix imsld]" : "$title" }]
    set activity_description_list [imsld::parse::parse_and_create_activity_description -activity_description_node $activity_description \
                                       -manifest_id $manifest_id \
                                       -manifest $manifest \
                                       -activity_name $title \
                                       -parent_id $parent_id \
                                       -tmp_dir $tmp_dir]

    set activity_description_id [lindex $activity_description_list 0]
    if { !$activity_description_id } {
        # there is an error, abort and return the list with the error
        return $activity_description_list
    }
    
    # Support Activity: Complete Activity
    # If the support activity has a "user choice" node, the learner decides when the activity is completed
    # otherwise, the activity ends when "time-limit" is complete.
    # When this element does not occur, the activity is set to 'completed' by default.
    
    set complete_activity [$activity_node selectNodes "*\[local-name()='complete-activity'\]"]
    set user_choice_p f
    set complete_act_id ""
    set time_in_seconds ""
    set when_prop_value_is_set_xml ""
    if { [llength $complete_activity] } {
        imsld::parse::validate_multiplicity -tree $complete_activity -multiplicity 1 -element_name complete-activity(support-activity) -equal
        
        # Support Activity: Complete Activity: User Choice
        set user_choice [$complete_activity selectNodes "*\[local-name()='user-choice'\]"]
        if { [llength $user_choice] } {
            imsld::parse::validate_multiplicity -tree $user_choice -multiplicity 1 -element_name user-choice(support-activity) -equal
            # that's it, the learner decides when the activity is completed
            set user_choice_p t
        }

        # Support Activity: Complete Activity: Time Limit
        set time_limit [$complete_activity selectNodes "*\[local-name()='time-limit'\]"]
        if { [llength $time_limit] } {
            imsld::parse::validate_multiplicity -tree $time_limit -multiplicity 1 -element_name time-limit(support-activity) -equal
            set time_string [imsld::parse::get_element_text -node $time_limit]
            set time_in_seconds [imsld::parse::convert_time_to_seconds -time $time_string]
        }
        
        # Support Activity: Complete Activity: When Property Value is Set
        set when_prop_value_is_set [$complete_activity selectNodes "*\[local-name()='when-property-value-is-set'\]"] 
        if { [llength $when_prop_value_is_set] } {
            imsld::parse::validate_multiplicity -tree $when_prop_value_is_set -multiplicity 1 -element_name when-property-valye-is-set(support-activity) -equal
            # create a node where the when-property-value-is-set will be stored
            set temporal_doc [dom createDocument when-property-value-is-set]
            set temporal_node [$temporal_doc documentElement]
            
            $temporal_node appendChild $when_prop_value_is_set
            set when_prop_value_is_set_xml [$temporal_node asXML]
        }
        set complete_act_id [imsld::item_revision_new -attributes [list [list time_in_seconds $time_in_seconds] \
                                                                       [list user_choice_p $user_choice_p] \
                                                                       [list when_prop_val_is_set_xml $when_prop_value_is_set_xml]] \
                                 -content_type imsld_complete_act \
                                 -parent_id $parent_id]

        if { [llength $when_prop_value_is_set] } {
            #search properties in expression 
            set property_nodes_list [$when_prop_value_is_set selectNodes {.//*[local-name()='property-ref']}]
            foreach property $property_nodes_list {
                set property_id [imsld::get_property_item_id -identifier [$property getAttribute ref] -imsld_id [db_string get_imsld_id {select imsld_id from imsld_componentsi where item_id = :component_id}]]
                # map the property with the complete_act_id
                relation_add imsld_prop_wpv_is_rel $property_id $complete_act_id
            }
        }

    }

    # Support Activity: On completion
    set on_completion [$activity_node selectNodes "*\[local-name()='on-completion'\]"]
    set on_completion_id ""
    set change_property_value_xml ""
    if { [llength $on_completion] } {
        imsld::parse::validate_multiplicity -tree $on_completion -multiplicity 1 -element_name on-completion(support-activity) -equal

        # Support Activity: On Completion: Change Property Value
        set change_property_value_list [$on_completion selectNodes "*\[local-name()='change-property-value'\]"] 
        if { [llength $change_property_value_list] } {
            # create a node where all the change-property-values will be stored
            set temporal_doc [dom createDocument change-property-values]
            set temporal_node [$temporal_doc documentElement]
            
            $temporal_node appendChild $change_property_value_list
            set change_property_value_xml [$temporal_node asXML]
        }

        set feedback_desc [$on_completion selectNodes "*\[local-name()='feedback-description'\]"]
        if { [llength $feedback_desc] } {
            imsld::parse::validate_multiplicity -tree $feedback_desc -multiplicity 1 -element_name feedback(support-activity) -equal
            set feedback_title [imsld::parse::get_title -node $feedback_desc -prefix imsld]
            set on_completion_id [imsld::item_revision_new -parent_id $parent_id \
                                      -content_type imsld_on_completion \
                                      -attributes [list [list feedback_title $feedback_title] \
                                                       [list change_property_value_xml $change_property_value_xml]]]
            set feedback_items [$feedback_desc selectNodes "*\[local-name()='item'\]"]
            foreach feedback_item $feedback_items {
                set item_list [imsld::parse::parse_and_create_item -manifest $manifest \
                                   -manifest_id $manifest_id \
                                   -item_node $feedback_item \
                                   -parent_id $parent_id \
                                   -tmp_dir $tmp_dir]
                set item_id [lindex $item_list 0]
                if { !$item_id } {
                    # an error happened, abort and return the list whit the error
                    return $item_list
                }
                # map item with the support objective
                relation_add imsld_feedback_rel $on_completion_id $item_id
            }
        } else {
            set on_completion_id [imsld::item_revision_new -parent_id $parent_id \
                                      -content_type imsld_on_completion \
                                      -attributes [list [list change_property_value_xml $change_property_value_xml]]]
        }
    }

    # crete support activity
    set support_activity_id [imsld::item_revision_new -attributes [list [list identifier $identifier] \
                                                                       [list component_id $component_id] \
                                                                       [list activity_description_id $activity_description_id] \
                                                                       [list parameters $parameters] \
                                                                       [list is_visible_p $is_visible_p] \
                                                                       [list complete_act_id $complete_act_id] \
                                                                       [list on_completion_id $on_completion_id]] \
                                 -content_type imsld_support_activity \
                                 -title $title \
                                 -parent_id $parent_id]
    
    # to avoid infinite loops, take the notifications parsing out
    if { [llength $on_completion] } {
        # Support Activity: On Completion: Notifications
        set notifications_list [$on_completion selectNodes "*\[local-name()='notification'\]"] 
        if { [llength $notifications_list] } {
            foreach notification $notifications_list {
                set notification_list [imsld::parse::parse_and_create_notification -component_id $component_id \
                                           -notification_node $notification \
                                           -manifest $manifest \
                                           -manifest_id $manifest_id \
                                           -parent_id $parent_id \
                                           -tmp_dir $tmp_dir]
                set notification_id [lindex $notification_list 0]
                if { !$notification_id } {
                    # an error occurred, return it
                    return $notification_list
                }

                # map on_completion with the notif
                relation_add imsld_on_comp_notif_rel $on_completion_id $notification_id
            }
        }
    }

    # Support Activity: Role ref
    set role_ref_list [$activity_node selectNodes "*\[local-name()='role-ref'\]"]
    foreach role_ref $role_ref_list {
        set ref [imsld::parse::get_attribute -node $role_ref -attr_name ref]
        if { ![db_0or1row get_role_id {
            select item_id as role_id 
            from imsld_rolesi 
            where identifier = :ref 
            and content_revision__is_live(role_id) = 't' 
            and component_id = :component_id
        }] } {
            # there is no role with that identifier, return the error
            return [list 0 "[_ imsld.lt_There_is_no_role_with_5]"]
        }
        # map support activity with the role
        relation_add imsld_sa_role_rel $support_activity_id $role_id
    }

    # Support Activity: Environments
    set environment_refs [$activity_node selectNodes "*\[local-name()='environment-ref'\]"]
    if { [llength $environment_refs] } {
        foreach environment_ref_node $environment_refs {
            # the environments have been already parsed by now, 
            # so the referenced environment has to be in the database.
            # If not found, return the error
            set environment_ref [imsld::parse::get_attribute -node $environment_ref_node -attr_name ref]
            if { ![db_0or1row get_environment_id {
                select item_id as environment_id
                from imsld_environmentsi 
                where identifier = :environment_ref 
                and content_revision__is_live(environment_id) = 't' 
                and component_id = :component_id
            }] } {
                # error, referenced environment does not exist
                return [list 0 "[_ imsld.lt_Referenced_environmen_2]"]
            }

            # map environment with support-activity
            relation_add imsld_sa_env_rel $support_activity_id $environment_id
        }
    }
    return $support_activity_id
}

ad_proc -public imsld::parse::parse_and_create_activity_structure { 
    -component_id
    -activity_node
    -manifest
    -manifest_id
    -parent_id
    -tmp_dir
} {
    Parse a activity structure and stores all the information in the database.

    Returns a list with the new activivty_structure_id (item_id) created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param component_id Component identifier which this role belongs to
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param activity_node The activity structure node to parse 
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
} {
    upvar files_struct_list files_struct_list
    upvar warnings warnings

    # get the info of the activity structure and create it
    set identifier [imsld::parse::get_attribute -node $activity_node -attr_name identifier]
    set number_to_select [imsld::parse::get_attribute -node $activity_node -attr_name number-to-select]
    set sort [imsld::parse::get_attribute -node $activity_node -attr_name sort]
    set sort [expr { [string eq "" $sort] ? "as-is" : "[string tolower $sort]" }]
    set structure_type [imsld::parse::get_attribute -node $activity_node -attr_name structure-type]
    set title [imsld::parse::get_title -node $activity_node -prefix imsld]
    
    # because of the complexity of the manifest, the activity structure may be already crated
    if { [db_0or1row already_crated {
        select item_id as activity_structure_id
        from imsld_activity_structuresi
        where component_id = :component_id
        and identifier = :identifier
        and structure_type = :structure_type
    }] } {
        return $activity_structure_id
    }
    
    # crete activity structure
    set activity_structure_id [imsld::item_revision_new -attributes [list [list identifier $identifier] \
                                                                         [list number_to_select $number_to_select] \
                                                                         [list sort $sort] \
                                                                         [list structure_type $structure_type] \
                                                                         [list component_id $component_id]] \
                                   -content_type imsld_activity_structure \
                                   -title $title \
                                   -parent_id $parent_id]
    
    # activity structure information
    set structure_information [$activity_node selectNodes "*\[local-name()='information'\]"]
    if { [llength $structure_information] } {
        # parse the item, create it and map it to the activity structure
        set information_item [$structure_information selectNodes "*\[local-name()='item'\]"]
        if { ![llength $information_item] } {
            return [list 0 "[_ imsld.lt_Information_given_but_1]"]
        }

        set item_list [imsld::parse::parse_and_create_item -manifest $manifest \
                           -manifest_id $manifest_id \
                           -item_node $information_item \
                           -parent_id $parent_id \
                           -tmp_dir $tmp_dir]
        
        set information_id [lindex $item_list 0]
        if { !$information_id } {
            # an error happened, abort and return the list whit the error
            return $item_list
        }
        # map information item with the activity structure
        relation_add imsld_as_info_i_rel $activity_structure_id $information_id
    }

    # store the order of the activities to display them later in the correct order
    set sort_order 0
    foreach node_ref [$activity_node childNodes] {

        # Activity Structure: Environments
        set environment_refs [$activity_node selectNodes "*\[local-name()='environment-ref'\]"]
        if { [string eq [$node_ref nodeName] imsld:environment-ref] } {
            # the environments have been already parsed by now, 
            # so the referenced environment has to be in the database.
            # If not found, return the error
            set environment_ref [imsld::parse::get_attribute -node $node_ref -attr_name ref]
            if { ![db_0or1row get_environment_id {
                select item_id as environment_id 
                from imsld_environmentsi
                where identifier = :environment_ref 
                and content_revision__is_live(environment_id) = 't' 
                and component_id = :component_id
            }] } {
                # error, referenced environment does not exist
                return [list 0 "[_ imsld.lt_Referenced_environmen_3]"]
            }
            
            # map environment with activity structure
            relation_add imsld_as_env_rel $activity_structure_id $environment_id
        }
      
        # Activity Structure: Learning Activities ref
        if { [string eq [$node_ref nodeName] imsld:learning-activity-ref] } {
            # the learning activities have been already parsed by now, so the referenced learning activity has to be in the database.
            # If not, return the error
            set learning_activity_ref [imsld::parse::get_attribute -node $node_ref -attr_name ref]
            if { ![db_0or1row get_learning_activity_id {
                select item_id as activity_id,
                activity_id as learning_activity_id
                from imsld_learning_activitiesi
                where identifier = :learning_activity_ref 
                and content_revision__is_live(activity_id) = 't' 
                and component_id = :component_id
            }] } {
                # may be the reference is wrong, search in the support activityes before returning an error
                if { ![db_0or1row get_learning_support_activity_id {
                    select item_id as activity_id,
                    activity_id as support_activity_id
                    from imsld_support_activitiesi
                    where identifier = :learning_activity_ref 
                    and content_revision__is_live(activity_id) = 't' 
                    and component_id = :component_id
                }] } {
                    # ok, last try: searching in the rest of activity structures...
                    if { [db_0or1row get_struct_id_from_la_ref {
                        select item_id as refrenced_struct_id,
                        structure_id
                        from imsld_activity_structuresi 
                        where identifier = :learning_activity_ref 
                        and content_revision__is_live(structure_id) = 't' 
                        and component_id = :component_id
                    }] } {
                        # warning message
                        append warnings "<li> [_ imsld.lt_Referenced_support_ac] </li>"
                        set extra_vars [ns_set create]
                        oacs_util::vars_to_ns_set \
                            -ns_set $extra_vars \
                            -var_list { sort_order }
                        
                        # do the mappings
                        relation_add -extra_vars $extra_vars imsld_as_as_rel $activity_structure_id $refrenced_struct_id 
                        incr sort_order
                    } else {
                        # search in the manifest ...
                        set organizations [$manifest selectNodes {*[local-name()=organizations]}]
                        set activity_structures [$organizations {*[local-name()='learning-design']/*[local-name()='components']/*[local-name()='activities']/*[local-name()='activity-structure']}]
#                        set activity_structures [[[[$organizations child all imsld:learning-design] child all imsld:components] child all imsld:activities] child all imsld:activity-structure]
                        
                        set found_p 0
                        foreach referenced_activity_structure $activity_structures {
                            set referenced_identifier [imsld::parse::get_attribute -node $referenced_activity_structure -attr_name identifier]
                            if { [string eq $learning_activity_ref $referenced_identifier] } {
                                set found_p 1
                                set referenced_structure_node $referenced_activity_structure
                            }
                        }
                        if { $found_p } {
                            # ok, let's create the activity structure
                            set activity_structure_ref_list [imsld::parse::parse_and_create_activity_structure -activity_node $referenced_structure_node \
                                                                 -component_id $component_id \
                                                                 -manifest_id $manifest_id \
                                                                 -manifest $manifest \
                                                                 -parent_id $parent_id \
                                                                 -tmp_dir $tmp_dir]
                            
                            set activity_structure_ref_id [lindex $activity_structure_ref_list 0]
                            if { !$activity_structure_ref_id } {
                                # there is an error, abort and return the list with the error
                                return $activity_structure_ref_list
                            }
                            # warning message
                            append warnings "<li> [_ imsld.lt_Referenced_learning_a] </li>"
                            set extra_vars [ns_set create]
                            oacs_util::vars_to_ns_set \
                                -ns_set $extra_vars \
                                -var_list { sort_order }
                            # finally, do the mappings
                            relation_add -extra_vars $extra_vars imsld_as_as_rel $activity_structure_id $activity_structure_ref_id
                            incr sort_order
                        } else {
                            # error, referenced learning activity does not exist
                            return [list 0 "[_ imsld.lt_Referenced_learning_a_1]"]
                        }
                    }
                } else {
                    # warning message
                    append warnings "<li> [_ imsld.lt_Referenced_learning_a_2] </li>"
                    # map support activity with activity structure
                    set extra_vars [ns_set create]
                    oacs_util::vars_to_ns_set \
                        -ns_set $extra_vars \
                        -var_list { sort_order }
                    relation_add -extra_vars $extra_vars imsld_as_sa_rel $activity_structure_id $activity_id
                    incr sort_order
                }
            } else {
                # map learning activity with activity structure
                set extra_vars [ns_set create]
                oacs_util::vars_to_ns_set \
                    -ns_set $extra_vars \
                    -var_list { sort_order }
                relation_add -extra_vars $extra_vars imsld_as_la_rel $activity_structure_id $activity_id
                incr sort_order
            }
        }
        
        # Activity Structure: Support Activities ref
        if { [string eq [$node_ref nodeName] imsld:support-activity-ref] } {
                
            # the support activities have been already parsed by now, so the referenced support activity has to be in the database.
            # If not, return the error
            set support_activity_ref [imsld::parse::get_attribute -node $node_ref -attr_name ref]
            if { ![db_0or1row get_support_activity_id {
                select item_id as activity_id,
                activity_id as support_activity_id
                from imsld_support_activitiesi 
                where identifier = :support_activity_ref 
                and content_revision__is_live(activity_id) ='t' 
                and component_id = :component_id
            }] } {
                # may be the reference is wrong, search in the support activityes before returning an error
                if { ![db_0or1row get_support_learning_activity_id {
                    select item_id as activity_id,
                    activity_id as learning_activity_id
                    from imsld_learning_activitiesi
                    where identifier = :support_activity_ref 
                    and content_revision__is_live(activity_id) = 't' 
                    and component_id = :component_id
                }] } {
                    # ok, last try: searching in the rest of activity structures...
                    if { [db_0or1row get_struct_id_from_sa_ref {
                        select item_id as refrenced_struct_id,
                        structure_id
                        from imsld_activity_structuresi 
                        where identifier = :support_activity_ref 
                        and content_revision__is_live(structure_id) = 't' 
                        and component_id = :component_id
                    }] } {
                        # warning message
                        append warnings "<li> [_ imsld.lt_Referenced_support_ac_1] </li>"
                        set extra_vars [ns_set create]
                        oacs_util::vars_to_ns_set \
                            -ns_set $extra_vars \
                            -var_list { sort_order }
                        # do the mappings
                        relation_add -extra_vars $extra_vars imsld_as_as_rel $activity_structure_id $refrenced_struct_id
                        incr sort_order
                    } else {
                        # search in the manifest ...
                        set organizations [$manifest selectNodes {*[local-name()='organizations']}]
                        set activity_structures [$organizations selectNodes {*[local-name()='learning-design']/*[local-name()='components']/*[local-name()='activities']/*[local-name()='activity-structure']}]
                        
                        set found_p 0
                        foreach referenced_activity_structure $activity_structures {
                            set referenced_identifier [imsld::parse::get_attribute -node $referenced_activity_structure -attr_name identifier]
                            if { [string eq $support_activity_ref $referenced_identifier] } {
                            set found_p 1
                                set referenced_structure_node $referenced_activity_structure
                            }
                        }
                        if { $found_p } {
                            # ok, let's create the activity structure
                            set activity_structure_ref_list [imsld::parse::parse_and_create_activity_structure -activity_node $referenced_structure_node \
                                                                 -component_id $component_id \
                                                                 -manifest_id $manifest_id \
                                                                 -manifest $manifest \
                                                                 -parent_id $parent_id \
                                                                 -tmp_dir $tmp_dir]
                            
                            set activity_structure_ref_id [lindex $activity_structure_ref_list 0]
                            if { !$activity_structure_ref_id } {
                                # there is an error, abort and return the list with the error
                                return $activity_structure_ref_list
                            }
                            # warning message
                            append warnings "<li> [_ imsld.lt_Referenced_support_ac_1] </li>"
                            set extra_vars [ns_set create]
                            oacs_util::vars_to_ns_set \
                                -ns_set $extra_vars \
                                -var_list { sort_order }
                            # finally, do the mappings
                            relation_add -extra_vars $extra_vars imsld_as_as_rel $activity_structure_id $activity_structure_ref_id
                            incr sort_order
                        } else {
                            # error, referenced support activity does not exist
                            return [list 0 "[_ imsld.lt_Referenced_support_ac_2]"]
                        }
                    }
                } else {
                    # warning message
                    append warnings "<li> [_ imsld.lt_Referenced_support_ac_3] </li>"
                    set extra_vars [ns_set create]
                    oacs_util::vars_to_ns_set \
                        -ns_set $extra_vars \
                        -var_list { sort_order }
                    # map the learning activity with activity structure
                    relation_add -extra_vars $extra_vars imsld_as_la_rel $activity_structure_id $activity_id
                    incr sort_order
                }
            } else {
                set extra_vars [ns_set create]
                oacs_util::vars_to_ns_set \
                    -ns_set $extra_vars \
                    -var_list { sort_order }
                # map support activity with activity structure
                relation_add -extra_vars $extra_vars imsld_as_sa_rel $activity_structure_id $activity_id
                incr sort_order
            }
        }
       
        # TO-DO: Unit of Learning ref ?

        # Activity Structure: Activity Structures ref
        if { [string eq [$node_ref nodeName] imsld:activity-structure-ref] } {
            set ref [imsld::parse::get_attribute -node $node_ref -attr_name ref]
            # we have to search for the referenced activity structure and there are two cases:
            # 1. the referenced activity structure has already been created: get the id from the database and do the mappings
            # 2. the referenced activity structure hasn't been created: invoke the parse_and_create_activity_structure proc,
            #    but first verify that the activity structure exists in the manifest
            if { [db_0or1row get_struct_id_from_as_ref {
                select item_id as refrenced_struct_id,
                structure_id
                from imsld_activity_structuresi 
                where identifier = :ref 
                and content_revision__is_live(structure_id) = 't' 
                and component_id = :component_id
            }] } {
                set extra_vars [ns_set create]
                oacs_util::vars_to_ns_set \
                    -ns_set $extra_vars \
                    -var_list { sort_order }
                # case one, just do the mappings
                relation_add -extra_vars $extra_vars imsld_as_as_rel $activity_structure_id $refrenced_struct_id
                incr sort_order
            } else {
                 # case two, first verify that the referenced activity structure exists
                set organizations [$manifest selectNodes {*[local-name()='organizations']}]
                set activity_structures [$organizations selectNodes {*[local-name()='learning-design']/*[local-name()='components']/*[local-name()='activities']/*[local-name()='activity-structure']}]
#                    set activity_structures [[[[$organizations child all imsld:learning-design] child all imsld:components] child all imsld:activities] child all imsld:activity-structure]

                set found_p 0
                foreach referenced_activity_structure $activity_structures {
                    set referenced_identifier [imsld::parse::get_attribute -node $referenced_activity_structure -attr_name identifier]
                    if { [string eq $ref $referenced_identifier] } {
                        set found_p 1
                        set referenced_structure_node $referenced_activity_structure
                    }
                }
                if { $found_p } {
                    # ok, let's create the activity structure
                    set activity_structure_ref_list [imsld::parse::parse_and_create_activity_structure -activity_node $referenced_structure_node \
                                                         -component_id $component_id \
                                                         -manifest_id $manifest_id \
                                                         -manifest $manifest \
                                                         -parent_id $parent_id \
                                                         -tmp_dir $tmp_dir]

                    set activity_structure_ref_id [lindex $activity_structure_ref_list 0]
                    if { !$activity_structure_ref_id } {
                        # there is an error, abort and return the list with the error
                        return $activity_structure_ref_list
                    }
                    set extra_vars [ns_set create]
                    oacs_util::vars_to_ns_set \
                        -ns_set $extra_vars \
                        -var_list { sort_order }
                    # finally, do the mappings
                    relation_add -extra_vars $extra_vars imsld_as_as_rel $activity_structure_id $activity_structure_ref_id
                    incr sort_order
                } else {
                    # error, return
                    return [list 0 "[_ imsld.lt_Referenced_activity_s]"]
                }
            }
        }
    }
    return $activity_structure_id
}

ad_proc -public imsld::parse::parse_and_create_role_part { 
    -act_id
    -role_part_node
    -manifest
    -manifest_id
    -parent_id
    -tmp_dir
    -sort_order
} {
    Parse a role part and stores all the information in the database.

    Returns a list with the new role_part_id (item_id) created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param act_id Act identifier which this role part belongs to
    @param role_part_node The role part node to parse 
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
    @param sort_order
} {
    upvar warnings warnings
    # get the info of the role part and create it
    set identifier [imsld::parse::get_attribute -node $role_part_node -attr_name identifier]
    set title [imsld::parse::get_title -node $role_part_node -prefix imsld]
    set component_id [db_string get_component_id {
        select cr4.item_id as component_id 
        from imsld_components ic, imsld_methods im, imsld_plays ip, imsld_acts ia,
        cr_revisions cr0, cr_revisions cr1, cr_revisions cr2, cr_revisions cr3, cr_revisions cr4
        where cr4.revision_id = ic.component_id
        and content_revision__is_live(ic.component_id) = 't'
        and ic.imsld_id = cr3.item_id
        and content_revision__is_live(cr3.revision_id) = 't'
        and cr3.item_id = im.imsld_id
        and im.method_id = cr2.revision_id
        and cr2.item_id = ip.method_id
        and ip.play_id = cr1.revision_id
        and cr1.item_id = ia.play_id
        and ia.act_id = cr0.revision_id
        and cr0.item_id = :act_id
    }]

    # Role Part: Roles
    set role_id ""
    set role_ref [$role_part_node selectNodes "*\[local-name()='role-ref'\]"]
    if { [llength $role_ref] } {
        imsld::parse::validate_multiplicity -tree $role_ref -multiplicity 1 -element_name role-ref(role-part) -equal
        # the roles have already been parsed by now, so the referenced role has to be in the database.
        # If not, return the error
        set role_ref_ref [imsld::parse::get_attribute -node $role_ref -attr_name ref]
        if { ![db_0or1row get_role_id {
            select ir.item_id as role_id
            from imsld_rolesi ir
            where ir.identifier = :role_ref_ref 
            and content_revision__is_live(ir.role_id) = 't' 
            and ir.component_id = :component_id}] } {
            # error, referenced role does not exist
            return [list 0 "[_ imsld.lt_Referenced_role_role_]"]
        }
    }

    # Role Part: Learning Activities
    set learning_activity_id ""
    set support_activity_id ""
    set activity_structure_id ""

    set learning_activity_ref [$role_part_node selectNodes "*\[local-name()='learning-activity-ref'\]"]
    if { [llength $learning_activity_ref] } {
        imsld::parse::validate_multiplicity -tree $learning_activity_ref -multiplicity 1 -element_name learning-activity-ref(role-part) -equal
        # the learning activities have already been parsed by now, so the referenced learning activity has to be in the database.
        # If not, return the error
        set learning_activity_ref_ref [imsld::parse::get_attribute -node $learning_activity_ref -attr_name ref]
        if { ![db_0or1row get_learning_activity_id {
            select la.item_id as learning_activity_id
            from imsld_learning_activitiesi la
            where la.identifier = :learning_activity_ref_ref 
            and content_revision__is_live(la.activity_id) = 't' 
            and la.component_id = :component_id
        }] } {
            # may be the reference is wrong, search in the support activityes before returning an error
            if { ![db_0or1row get_learning_support_activity_id {
                select item_id as support_activity_id 
                from imsld_support_activitiesi
                where identifier = :learning_activity_ref_ref 
                and content_revision__is_live(activity_id) = 't' 
                and component_id = :component_id
            }] } {
                # may be the reference is wrong, search in the activity structures before returning an error
                if { ![db_0or1row get_learning_activity_struct_id {
                    select item_id as activity_structure_id 
                    from imsld_activity_structuresi
                    where identifier = :learning_activity_ref_ref 
                    and content_revision__is_live(structure_id) = 't' 
                    and component_id = :component_id
                }] } {
                    # error, referenced learning activity does not exist
                    return [list 0 "[_ imsld.lt_Referenced_learning_a_3]"]
                } else {
                    # warning message
                    append warnings "<li> [_ imsld.lt_Referenced_learning_a_4] </li>"
                }
            } else {
                # warning message
                append warnings "<li> [_ imsld.lt_Referenced_learning_a_5] </li>"
            }
        }
    }

    # Role Part: Support Activities
    set support_activity_ref [$role_part_node selectNodes "*\[local-name()='support-activity-ref'\]"]
    if { [llength $support_activity_ref] } {
        imsld::parse::validate_multiplicity -tree $support_activity_ref -multiplicity 1 -element_name support-activity-ref(role-part) -equal
        # the support activities have already been parsed by now, so the referenced support activity has to be in the database.
        # If not, return the error
        set support_activity_ref_ref [imsld::parse::get_attribute -node $support_activity_ref -attr_name ref]
        if { ![db_0or1row get_support_activity_id {
            select sa.item_id as support_activity_id 
            from imsld_support_activitiesi sa
            where sa.identifier = :support_activity_ref_ref 
            and content_revision__is_live(sa.activity_id) = 't' 
            and sa.component_id = :component_id
        }] } {
            # may be the reference is wrong, search in the learning activities before returning an error
            if { ![db_0or1row get_support_learning_activity_id {
                select item_id as learning_activity_id 
                from imsld_learning_activitiesi
                where identifier = :support_activity_ref_ref 
                and content_revision__is_live(activity_id) = 't' 
                and component_id = :component_id
            }] } {
                # may be the reference is wrong, search in the activity structures before returning an error
                if { ![db_0or1row get_support_activity_struct_id {
                    select item_id as activity_structure_id 
                    from imsld_activity_structuresi
                    where identifier = :support_activity_ref_ref 
                    and content_revision__is_live(structure_id) = 't' 
                    and component_id = :component_id
                }] } {
                    # error, referenced support activity does not exist
                    return [list 0 "[_ imsld.lt_Referenced_support_ac_4]"]
                } else {
                    # warning message
                    append warnings "<li> [_ imsld.lt_Referenced_support_ac_5] </li>"
                }
            } else {
                # warning message
                append warnings "<li> [_ imsld.lt_Referenced_support_ac_6] </li>"
            }
        }
    }

    # TO-DO: Role Part: Units of Learning

    # Role Part: Activity Structures
    set activity_structure_ref [$role_part_node selectNodes "*\[local-name()='activity-structure-ref'\]"]
    if { [llength $activity_structure_ref] } {
        imsld::parse::validate_multiplicity -tree $activity_structure_ref -multiplicity 1 -element_name activity-structure-ref(role-part) -equal
        # the activity structures have already been parsed by now, so the referenced activity structure has to be in the database.
        # If not, return the error
        set activity_structure_ref_ref [imsld::parse::get_attribute -node $activity_structure_ref -attr_name ref]
        if { ![db_0or1row get_activity_structure_id {
            select ias.item_id as activity_structure_id 
            from imsld_activity_structuresi ias
            where ias.identifier = :activity_structure_ref_ref 
            and content_revision__is_live(ias.structure_id) = 't' 
            and ias.component_id = :component_id
        }] } {
            # may be the reference is wrong, search in the learning activities before returning an error
            if { ![db_0or1row get_struct_learning_activity_id {
                select item_id as learning_activity_id 
                from imsld_learning_activitiesi
                where identifier = :activity_structure_ref_ref 
                and content_revision__is_live(activity_id) = 't' 
                and component_id = :component_id
            }] } {
                # may be the reference is wrong, search in the support activities before returning an error
                if { ![db_0or1row get_struct_support_activity_id {
                    select item_id as support_activity_id 
                    from imsld_support_activitiesi
                    where identifier = :activity_structure_ref_ref 
                    and content_revision__is_live(activity_id) = 't' 
                    and component_id = :component_id
                }] } {
                    # error, referenced activity structure does not exist
                    return [list 0 "[_ imsld.lt_Referenced_activity_s_1]"]
                } else {
                    # warning message
                    append warnings "<li> [_ imsld.lt_Referenced_activity_s_2] </li>"
                }
            } else {
                # warning message
                append warnings "<li> [_ imsld.lt_Referenced_activity_s_3] </li>"
            }
        }
    }

    # Role Part: Environments
    set environment_ref [$role_part_node selectNodes "*\[local-name()='environment-ref'\]"]
    set environment_id ""
    if { [llength $environment_ref] } {
        imsld::parse::validate_multiplicity -tree $environment_ref -multiplicity 1 -element_name environment-ref(role-part) -equal
        # the environments have already been parsed by now, so the referenced environment has to be in the database.
        # If not, return the error
        set environment_ref_ref [imsld::parse::get_attribute -node $environment_ref -attr_name ref]
        if { ![db_0or1row get_env_id {
            select env.item_id as environment_id 
            from imsld_environmentsi env
            where env.identifier = :environment_ref_ref 
            and content_revision__is_live(env.environment_id) = 't' 
            and env.component_id = :component_id
        }] } {
            # error, referenced environment does not exist
            return [list 0 "[_ imsld.lt_Referenced_environmen_4]"]
        }
    }
    
    set role_part_id [imsld::item_revision_new -attributes [list [list identifier $identifier] \
                                                                [list role_id $role_id] \
                                                                [list act_id $act_id] \
                                                                [list learning_activity_id $learning_activity_id] \
                                                                [list support_activity_id $support_activity_id] \
                                                                [list activity_structure_id $activity_structure_id] \
                                                                [list environment_id $environment_id] \
                                                                [list sort_order $sort_order]] \
                          -content_type imsld_role_part \
                          -title $title \
                          -parent_id $parent_id]

    return $role_part_id
}

ad_proc -public imsld::parse::parse_and_create_act { 
    -play_id
    -act_node
    -manifest
    -manifest_id
    -parent_id
    -tmp_dir
    -sort_order
} {
    Parse a act and stores all the information in the database.

    Returns a list with the new act_id (item_id) created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param play_id Play identifier which this act belongs to
    @param act_node The act node to parse 
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
    @param sort_order
} {
    upvar files_struct_list files_struct_list
    upvar warnings warnings

    # get the info of the act and create it
    set identifier [imsld::parse::get_attribute -node $act_node -attr_name identifier]
    set title [imsld::parse::get_title -node $act_node -prefix imsld]
    # get the info of the role part and create it
    db_1row get_info {
        select cr4.item_id as component_id,
        ip.play_id as play_revision_id
        from imsld_components ic, imsld_methods im, imsld_plays ip,
        cr_revisions cr1, cr_revisions cr2, cr_revisions cr3, cr_revisions cr4
        where cr4.revision_id = ic.component_id
        and content_revision__is_live(ic.component_id) = 't'
        and ic.imsld_id = cr3.item_id
        and content_revision__is_live(cr3.revision_id) = 't'
        and cr3.item_id = im.imsld_id
        and im.method_id = cr2.revision_id
        and cr2.item_id = ip.method_id
        and ip.play_id = cr1.revision_id
        and cr1.item_id = :play_id
    }
    
    # Act: Complete Act: Time Limit
    set complete_act [$act_node selectNodes "*\[local-name()='complete-act'\]"]
    set complete_act_id ""
    set time_in_seconds ""
    set when_prop_value_is_set_xml ""
    set when_condition_true_id ""
    if { [llength $complete_act] } {
        imsld::parse::validate_multiplicity -tree $complete_act -multiplicity 1 -element_name complete-act -equal
        # Act: Complete Act: Time Limit
        set time_limit [$complete_act selectNodes "*\[local-name()='time-limit'\]"]
        if { [llength $time_limit] } {
            imsld::parse::validate_multiplicity -tree $time_limit -multiplicity 1 -element_name time-limit(complete-act) -equal
            set time_string [imsld::parse::get_element_text -node $time_limit]
            set time_in_seconds [imsld::parse::convert_time_to_seconds -time $time_string]
        }
        # Act: Complete Act: When Property Value is Set
        set when_prop_value_is_set [$complete_act selectNodes "*\[local-name()='when-property-value-is-set'\]"] 
        if { [llength $when_prop_value_is_set] } {
            imsld::parse::validate_multiplicity -tree $when_prop_value_is_set -multiplicity 1 -element_name when-property-valye-is-set(complete-act) -equal
            # create a node where the when-property-value-is-set will be stored
            set temporal_doc [dom createDocument when-property-value-is-set]
            set temporal_node [$temporal_doc documentElement]
            
            $temporal_node appendChild $when_prop_value_is_set
            set when_prop_value_is_set_xml [$temporal_node asXML]
        }
        # Act: Complete Act: When Condition True
        set when_condition_true [$complete_act selectNodes "*\[local-name()='when-condition-true'\]"] 
        if { [llength $when_condition_true] } {
            imsld::parse::validate_multiplicity -tree $when_condition_true -multiplicity 1 -element_name when-condition-true(complete-act) -equal
            set role_ref [$when_condition_true selectNodes "*\[local-name()='role-ref'\]"]
            imsld::parse::validate_multiplicity -tree $role_ref -multiplicity 1 -element_name role-ref(when-condition-true) -equal
            # the roles have already been parsed by now, so the referenced role has to be in the database.
            # If not, return the error
            set role_ref_ref [imsld::parse::get_attribute -node $role_ref -attr_name ref]
            if { ![db_0or1row get_role_id {
                select ir.item_id as role_id
                from imsld_rolesi ir
                where ir.identifier = :role_ref_ref 
                and content_revision__is_live(ir.role_id) = 't' 
                and ir.component_id = :component_id}] } {
                # error, referenced role does not exist
                return [list 0 "[_ imsld.lt_Referenced_role_role_]"]
            }
            #select all but role-ref that is: select the expression node
            set temporal_doc [dom createDocument expression]
            set temporal_node [$temporal_doc documentElement]
            set expression [$when_condition_true selectNodes "*\[not(local-name()='role-ref')\]"]
            $temporal_node appendChild $expression

            imsld::parse::validate_multiplicity -tree $expression -multiplicity 1 -element_name "[$expression localName](when-condition-true)" -equal
            
            set when_condition_true_id [imsld::item_revision_new -attributes [list [list role_id $role_id] \
                                                                                  [list expression_xml [$temporal_node asXML]]] \
                                            -content_type imsld_when_condition_true \
                                            -parent_id $parent_id \
                                            -title $title]
            #search properties in expression 
            set property_nodes_list [$expression selectNodes {.//*[local-name()='property-ref']}]
            foreach property $property_nodes_list {
                set property_id [imsld::get_property_item_id -identifier [$property getAttribute ref] -play_id $play_revision_id]
                # map the property with the condition (when condition true)
                relation_add imsld_prop_whct_rel $property_id $when_condition_true_id 
            }
        }
        
        set complete_act_id [imsld::item_revision_new -attributes [list [list time_in_seconds $time_in_seconds] \
                                                                       [list when_condition_true_id $when_condition_true_id] \
                                                                       [list when_prop_val_is_set_xml $when_prop_value_is_set_xml]] \
                                 -content_type imsld_complete_act \
                                 -parent_id $parent_id]

        if { [llength $when_prop_value_is_set] } {
            #search properties in expression 
            set property_nodes_list [$when_prop_value_is_set selectNodes {.//*[local-name()='property-ref']}]
            foreach property $property_nodes_list {
                set property_id [imsld::get_property_item_id -identifier [$property getAttribute ref] -play_id $play_revision_id]
                # map the property with the complete_act_id
                relation_add imsld_prop_wpv_is_rel $property_id $complete_act_id
            }
        }

    }

    # Act: On Completion
    set on_completion [$act_node selectNodes "*\[local-name()='on-completion'\]"]
    set on_completion_id ""
    set change_property_value_xml ""
    if { [llength $on_completion] } {
        imsld::parse::validate_multiplicity -tree $on_completion -multiplicity 1 -element_name on-completion(complete-act) -equal

        # Act: On Completion: Change Property Value
        set change_property_value_list [$on_completion selectNodes "*\[local-name()='change-property-value'\]"] 
        if { [llength $change_property_value_list] } {
            # create a node where all the change-property-values will be stored
            set temporal_doc [dom createDocument change-property-values]
            set temporal_node [$temporal_doc documentElement]
            
            $temporal_node appendChild $change_property_value_list
            set change_property_value_xml [$temporal_node asXML]
        }

        set feedback_desc [$on_completion selectNodes "*\[local-name()='feedback-description'\]"]
        if { [llength $feedback_desc] } {
            imsld::parse::validate_multiplicity -tree $feedback_desc -multiplicity 1 -element_name feedback(complete-act) -equal
            set feedback_title [imsld::parse::get_title -node $feedback_desc -prefix imsld]
            set on_completion_id [imsld::item_revision_new -parent_id $parent_id \
                                      -content_type imsld_on_completion \
                                      -attributes [list [list feedback_title $feedback_title] \
                                                       [list change_property_value_xml $change_property_value_xml]]]
            set feedback_items [$feedback_desc selectNodes "*\[local-name()='item'\]"]
            foreach feedback_item $feedback_items {
                set item_list [imsld::parse::parse_and_create_item -manifest $manifest \
                                   -manifest_id $manifest_id \
                                   -item_node $feedback_item \
                                   -parent_id $parent_id \
                                   -tmp_dir $tmp_dir]
                set item_id [lindex $item_list 0]
                if { !$item_id } {
                    # an error happened, abort and return the list whit the error
                    return $item_list
                }
                # map item with the support objective
                relation_add imsld_feedback_rel $on_completion_id $item_id
            }
        } else {
            set on_completion_id [imsld::item_revision_new -parent_id $parent_id \
                                      -content_type imsld_on_completion \
                                      -attributes [list [list change_property_value_xml $change_property_value_xml]]]
        }
    }

    set act_id [imsld::item_revision_new -attributes [list [list play_id $play_id] \
                                                          [list identifier $identifier] \
                                                          [list complete_act_id $complete_act_id] \
                                                          [list on_completion_id $on_completion_id] \
                                                          [list sort_order $sort_order]] \
                    -content_type imsld_act \
                    -parent_id $parent_id \
                    -title $title]

    # to avoid infinite loops, take the notifications parsing out
    if { [llength $on_completion] } {
        # Act: On Completion: Notifications
        set notifications_list [$on_completion selectNodes "*\[local-name()='notification'\]"] 
        if { [llength $notifications_list] } {
            foreach notification $notifications_list {
                set notification_list [imsld::parse::parse_and_create_notification -component_id $component_id \
                                           -notification_node $notification \
                                           -manifest $manifest \
                                           -manifest_id $manifest_id \
                                           -parent_id $parent_id \
                                           -tmp_dir $tmp_dir]
                set notification_id [lindex $notification_list 0]
                if { !$notification_id } {
                    # an error occurred, return it
                    return $notification_list
                }
                # map on_completion with the notif
                relation_add imsld_on_comp_notif_rel $on_completion_id $notification_id
            }
        }
    }
    

    # Act: Role Parts
    set role_parts [$act_node selectNodes "*\[local-name()='role-part'\]"]
    imsld::parse::validate_multiplicity -tree $role_parts -multiplicity 1 -element_name role-parts -greather_than
    set count 1
    foreach role_part $role_parts {
        set role_part_list [imsld::parse::parse_and_create_role_part -act_id $act_id \
                                -role_part_node $role_part \
                                -manifest $manifest \
                                -manifest_id $manifest_id \
                                -parent_id $parent_id \
                                -tmp_dir $tmp_dir \
                                -sort_order $count]
        set role_part_id [lindex $role_part_list 0]
        if { !$role_part_id } {
            # an error happened, abort and return the list whit the error
            return $role_part_list
        }
        incr count
    }
    
    # Act: Complete Act: When role part comleted
    # The act is completed when the referenced role parts are completed

    set complete_act [$act_node selectNodes "*\[local-name()='complete-act'\]"]
    if { [llength $complete_act] } {
        imsld::parse::validate_multiplicity -tree $complete_act -multiplicity 1 -element_name complete-act -equal
        set when_rp_completed_list [$complete_act selectNodes "*\[local-name()='when-role-part-completed'\]"]
        foreach when_rp_completed $when_rp_completed_list {
            set ref [imsld::parse::get_attribute -node $when_rp_completed -attr_name ref]
            # verify that the referenced role part exists
            if { ![db_0or1row get_rp_id {
                select item_id as role_part_id 
                from imsld_role_partsi 
                where identifier = :ref 
                and content_revision__is_live(role_part_id) = 't' 
                and act_id = :act_id
            }] } {
                return [list 0 "[_ imsld.lt_The_referenced_role_p]"]
            }
            # found, map the role part (with the imsld_act_rp_completed_rel) with the act
            relation_add imsld_act_rp_completed_rel $act_id $role_part_id
        }
    }
    
    return $act_id
}

ad_proc -public imsld::parse::parse_and_create_play { 
    -method_id
    -play_node
    -manifest
    -manifest_id
    -parent_id
    -tmp_dir
    -sort_order
} {
    Parse a play and stores all the information in the database.

    Returns a list with the new play_id (item_id) created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param method_id method identifier which this play belongs to
    @param play_node The play node to parse 
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
    @param sort_order 
} {
    upvar files_struct_list files_struct_list
    upvar warnings warnings

    # get the info of the play and create it
    set identifier [imsld::parse::get_attribute -node $play_node -attr_name identifier]
    set is_visible_p [imsld::parse::get_bool_attribute -node $play_node -attr_name isvisible -default t]
    set title [imsld::parse::get_title -node $play_node -prefix imsld]
    
    # Play: Complete Play
    set complete_play [$play_node selectNodes "*\[local-name()='complete-play'\]"]
    set complete_act_id ""
    set time_in_seconds ""
    set when_last_act_completed_p f
    set when_prop_value_is_set_xml ""
    if { [llength $complete_play] } {
        imsld::parse::validate_multiplicity -tree $complete_play -multiplicity 1 -element_name complete-play -equal
        # Play: Complete Play: Time Limit
        set time_limit [$complete_play selectNodes "*\[local-name()='time-limit'\]"]
        if { [llength $time_limit] } {
            imsld::parse::validate_multiplicity -tree $time_limit -multiplicity 1 -element_name time-limit(complete-play) -equal
            set time_string [imsld::parse::get_element_text -node $time_limit]
            set time_in_seconds [imsld::parse::convert_time_to_seconds -time $time_string]
        }
        # Play: Complete Play: When Property Value is Set
        set when_prop_value_is_set [$complete_play selectNodes "*\[local-name()='when-property-value-is-set'\]"] 
        if { [llength $when_prop_value_is_set] } {
            imsld::parse::validate_multiplicity -tree $when_prop_value_is_set -multiplicity 1 -element_name when-property-valye-is-set(complete-play) -equal
            # create a node where the when-property-value-is-set will be stored
            set temporal_doc [dom createDocument when-property-value-is-set]
            set temporal_node [$temporal_doc documentElement]
            
            $temporal_node appendChild $when_prop_value_is_set
            set when_prop_value_is_set_xml [$temporal_node asXML]
        }
        # Play: Complete Play: When Last Act Completed
        set when_last_act_completed [$complete_play selectNodes "*\[local-name()='when-last-act-completed'\]"]
        if { [llength $when_last_act_completed] } {
            set when_last_act_completed_p t
        }
        set complete_act_id [imsld::item_revision_new -attributes [list [list time_in_seconds $time_in_seconds] \
                                                                       [list when_last_act_completed_p $when_last_act_completed_p] \
                                                                       [list when_prop_val_is_set_xml $when_prop_value_is_set_xml]] \
                                 -content_type imsld_complete_act \
                                 -parent_id $parent_id]
        if { [llength $when_prop_value_is_set] } {
            #search properties in expression 
            set property_nodes_list [$when_prop_value_is_set selectNodes {.//*[local-name()='property-ref']}]
            foreach property $property_nodes_list {
                set property_id [imsld::get_property_item_id -identifier [$property getAttribute ref] -imsld_id [db_string get_imsld_id {select imsld_id from imsld_methodsi where item_id = :method_id}]]
                # map the property with the complete_act_id
                relation_add imsld_prop_wpv_is_rel $property_id $complete_act_id
            }
        }

    }

    # Play: On Completion
    set on_completion [$play_node selectNodes "*\[local-name()='on-completion'\]"]
    set on_completion_id ""
    set change_property_value_xml ""
    if { [llength $on_completion] } {
        imsld::parse::validate_multiplicity -tree $on_completion -multiplicity 1 -element_name on-completion(complete-play) -equal

        # Play: On Completion: Change Property Value
        set change_property_value_list [$on_completion selectNodes "*\[local-name()='change-property-value'\]"] 
        if { [llength $change_property_value_list] } {
            # create a node where all the change-property-values will be stored
            set temporal_doc [dom createDocument change-property-values]
            set temporal_node [$temporal_doc documentElement]
            
            $temporal_node appendChild $change_property_value_list
            set change_property_value_xml [$temporal_node asXML]
        }

        set feedback_desc [$on_completion selectNodes "*\[local-name()='feedback-description'\]"]
        if { [llength $feedback_desc] } {
            imsld::parse::validate_multiplicity -tree $feedback_desc -multiplicity 1 -element_name feedback(complete-play) -equal
            set feedback_title [imsld::parse::get_title -node $feedback_desc -prefix imsld]
            set on_completion_id [imsld::item_revision_new -parent_id $parent_id \
                                      -content_type imsld_on_completion \
                                      -attributes [list [list feedback_title $feedback_title] \
                                                       [list change_property_value_xml $change_property_value_xml]]]
            set feedback_items [$feedback_desc selectNodes "*\[local-name()='item'\]"]
            foreach feedback_item $feedback_items {
                set item_list [imsld::parse::parse_and_create_item -manifest $manifest \
                                   -manifest_id $manifest_id \
                                   -item_node $feedback_item \
                                   -parent_id $parent_id \
                                   -tmp_dir $tmp_dir]
                set item_id [lindex $item_list 0]
                if { !$item_id } {
                    # an error happened, abort and return the list whit the error
                    return $item_list
                }
                # map item with the support objective
                relation_add imsld_feedback_rel $on_completion_id $item_id
            }
        } else {
            set on_completion_id [imsld::item_revision_new -parent_id $parent_id \
                                      -content_type imsld_on_completion \
                                      -attributes [list [list change_property_value_xml $change_property_value_xml]]]
        }
        
    }

    set play_id [imsld::item_revision_new -attributes [list [list method_id $method_id] \
                                                           [list is_visible_p $is_visible_p] \
                                                           [list identifier $identifier] \
                                                           [list complete_act_id $complete_act_id] \
                                                           [list on_completion_id $on_completion_id] \
                                                           [list sort_order $sort_order]] \
                     -content_type imsld_play \
                     -title $title \
                     -parent_id $parent_id]

    # to avoid infinite loops, take the notifications parsing out
    if { [llength $on_completion] } {
        # Play: On Completion: Notifications
        set notifications_list [$on_completion selectNodes "*\[local-name()='notification'\]"] 
        if { [llength $notifications_list] } {
            foreach notification $notifications_list {
                set notification_list [imsld::parse::parse_and_create_notification -method_id $method_id \
                                           -notification_node $notification \
                                           -manifest $manifest \
                                           -manifest_id $manifest_id \
                                           -parent_id $parent_id \
                                           -tmp_dir $tmp_dir]
                set notification_id [lindex $notification_list 0]
                if { !$notification_id } {
                    # an error occurred, return it
                    return $notification_list
                }
                # map on_completion with the notif
                relation_add imsld_on_comp_notif_rel $on_completion_id $notification_id
            }
        }
    }

    # Play: Acts
    set acts [$play_node selectNodes "*\[local-name()='act'\]"]
    imsld::parse::validate_multiplicity -tree $acts -multiplicity 1 -element_name acts -greather_than
    set count 1
    foreach act $acts {
        set act_identifier [imsld::parse::get_attribute -node $act -attr_name identifier]
        set act_title [imsld::parse::get_title -node $act -prefix imsld]
        set act_list [imsld::parse::parse_and_create_act -play_id $play_id \
                          -act_node $act \
                          -manifest $manifest \
                          -manifest_id $manifest_id \
                          -parent_id $parent_id \
                          -tmp_dir $tmp_dir \
                          -sort_order $count]
        set act_id [lindex $act_list 0]
        if { !$act_id } {
            # an error happened, abort and return the list whit the error
            return $act_list
        }
        incr count
    }
    
    return $play_id
}

ad_proc -public imsld::parse::parse_and_create_notification { 
    -component_id
    -method_id
    -notification_node:required
    -manifest:required
    -manifest_id:required
    -parent_id:required
    -tmp_dir:required
} {
    Parse a notification and stores all the information in the database.

    Returns a list with the new notification_id (item_id) created if there were no errors, or 0 and an explanation messge if there was an error.
    
    @option component_id Component identifier which the notification belongs
    @option imsld_id IMS-LD identifier which this notification belongs
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param notification_node The notification node to parse 
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
} {
    upvar files_struct_list files_struct_list
    upvar warnings warnings

    if { [info exists component_id] } {
        db_1row get_info_from_comp { *SQL* }
    }
    if { [info exists method_id] } {
        db_1row get_info_from_method { *SQL* }
    }

    set subject_node [$notification_node selectNodes "*\[local-name()='subject'\]"]
    imsld::parse::validate_multiplicity -tree $subject_node -multiplicity 1 -element_name "subject (notification)" -equal
    set subject [imsld::parse::get_element_text -node $subject_node]

    # notification: learning-activity-ref
    set la_ref [$notification_node selectNodes "*\[local-name()='learning-activity-ref'\]"]
    set activity_id ""
    if { [llength $la_ref] } {
        imsld::parse::validate_multiplicity -tree $la_ref -multiplicity 1 -element_name learning-activity-ref(notification) -equal
        # search in the already parsed activities

        set learning_activity_ref [imsld::parse::get_attribute -node $la_ref -attr_name ref]
        if { ![db_0or1row la_get_learning_activity_id { *SQL* }] } {
            # may be the reference is wrong, search in the support activityes before returning an error
            if { [db_0or1row la_get_learning_support_activity_id { *SQL* }] } {
                # warning message
                append warnings "<li> [_ imsld.lt_The_refernced_learnin] </li>"

            } else {
                # search in the manifest ...
                set organizations [$manifest selectNodes {*[local-name()='organizations']}]
                set learning_activities [$organizations selectNodes {*[local-name()='learning-design']/*[local-name()='components']/*[local-name()='activities']/*[local-name()='learning-activity']}]
                
                set found_p 0
                foreach referenced_learning_activity $learning_activities {
                    set referenced_identifier [imsld::parse::get_attribute -node $referenced_learning_activity -attr_name identifier]
                    if { [string eq $learning_activity_ref $referenced_identifier] } {
                        set found_p 1
                        set referenced_learning_activity_node $referenced_learning_activity
                    }
                }
                if { $found_p } {
                    # ok, let's create the learning activity
                    set learning_activity_ref_list [imsld::parse::parse_and_create_learning_activity -activity_node $referenced_learning_activity_node \
                                                         -component_id $component_id \
                                                         -manifest_id $manifest_id \
                                                         -manifest $manifest \
                                                         -parent_id $parent_id \
                                                         -tmp_dir $tmp_dir]
                    
                    set activity_id [lindex $learning_activity_ref_list 0]
                    if { !$activity_id } {
                        # there is an error, abort and return the list with the error
                        return $learning_activity_ref_list
                    }
                } else {
                    # error, referenced learning activity does not exist
                    return [list 0 "[_ imsld.lt_Referenced_learning_a_6]"]
                }
                
            }
        }
    }
    
    # notification: support-activity-ref
    set sa_ref [$notification_node selectNodes "*\[local-name()='support-activity-ref'\]"]
    if { [llength $sa_ref] } {
        imsld::parse::validate_multiplicity -tree $sa_ref -multiplicity 1 -element_name support-activity-ref(notification) -equal
        # search in the already parsed activities
        
        set support_activity_ref [imsld::parse::get_attribute -node $sa_ref -attr_name ref]
        if { ![db_0or1row sa_get_support_activity_id { *SQL* }] } {
            # may be the reference is wrong, search in the learning activityes before returning an error
            if { [db_0or1row sa_get_learning_activity_id { *SQL* }] } {
                # warning message
                append warnings "<li> [_ imsld.lt_The_refernced_support] </li>"

            } else {
                # search in the manifest ...
                set organizations [$manifest selectNodes {*[local-name()='organizations']}]
                set support_activities [$organizations selectNodes {*[local-name()='learning-design']/*[local-name()='components']/*[local-name()='activities']/*[local-name()='support-activity']}]
                
                set found_p 0
                foreach referenced_support_activity $support_activities {
                    set referenced_identifier [imsld::parse::get_attribute -node $referenced_support_activity -attr_name identifier]
                    if { [string eq $support_activity_ref $referenced_identifier] } {
                        set found_p 1
                        set referenced_support_activity_node $referenced_support_activity
                    }
                }
                if { $found_p } {
                    # ok, let's create the support activity
                    set support_activity_ref_list [imsld::parse::parse_and_create_support_activity -activity_node $referenced_support_activity_node \
                                                         -component_id $component_id \
                                                         -manifest_id $manifest_id \
                                                         -manifest $manifest \
                                                         -parent_id $parent_id \
                                                         -tmp_dir $tmp_dir]
                    
                    set activity_id [lindex $learning_activity_ref_list 0]
                    if { !$activity_id } {
                        # there is an error, abort and return the list with the error
                        return $support_activity_ref_list
                    }
                } else {
                    # error, referenced learning activity does not exist
                    return [list 0 "<#_ Referenced support activity (%support_activity_ref%) from notification does not exist"]
                }
                
            }
        }
    }

    # if we reached this point, the referenced activity is stored in the variable activity_id
    # lets create create the notification
    set notification_id [imsld::item_revision_new -attributes [list [list activity_id $activity_id] \
                                                                   [list subject $subject] \
                                                                   [list imsld_id $imsld_id]] \
                             -content_type imsld_notification \
                             -parent_id $parent_id]

    # notification: email data
    set email_data_list [$notification_node selectNodes "*\[local-name()='email-data'\]"]
    imsld::parse::validate_multiplicity -tree $email_data_list -multiplicity 1 -element_name email-data -greather_than
    foreach email_data $email_data_list {
        set role_ref [$email_data selectNodes "*\[local-name()='role-ref'\]"]
        imsld::parse::validate_multiplicity -tree $role_ref -multiplicity 1 -element_name role-ref(email-data) -equal
        set ref [imsld::parse::get_attribute -node $role_ref -attr_name ref]

        if { ![db_0or1row get_role_id_from_ref { *SQL* }] } {
            # there is no role with that identifier, return the error
            return [list 0 "[_ imsld.lt_There_is_no_role_with]"]
        }

        # email-property-ref
        set email_property_ref [imsld::parse::get_attribute -node $email_data -attr_name email-property-ref]
        if { ![string eq $email_property_ref ""] } {
            if { ![db_0or1row get_email_property_id { *SQL* }] } {
                # there is no property with that identifier, return the error
                return [list 0 "[_ imsld.lt_There_is_no_property__1]"]
            } 
        } else {
            set email_property_id ""
        }

        # username-property-ref
        set username_property_ref [imsld::parse::get_attribute -node $email_data -attr_name username-property-ref]
        if { ![string eq $username_property_ref ""] } {
            if { ![db_0or1row get_username_property_id { *SQL* }] } {
                # there is no property with that identifier, return the error
                return [list 0 "[_ imsld.lt_There_is_no_property__2]"]
            }
        } else {
            set username_property_id ""
        }
        
        set email_data_id [imsld::item_revision_new -attributes [list [list role_id $role_id] \
                                                                     [list mail_data {}] \
                                                                     [list email_property_id $email_property_id] \
                                                                     [list username_property_id $username_property_id]] \
                               -content_type imsld_send_mail_data \
                               -parent_id $parent_id]
        
        # do the mappings
        relation_add imsld_notif_email_rel $notification_id $email_data_id
    }
    return $notification_id
}

ad_proc -public imsld::parse::parse_and_create_if_then_else { 
    -condition_node
    -manifest
    -manifest_id
    -parent_id
    -method_id
} {
    Parse a condition and stores all the information in the database.

    Returns the if_then_else_id (item_id) if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param imsld_id IMS-LD identifier which this play belongs to
    @param condition_node The condition node to be parsed 
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param parent_id Parent folder ID
} {
    set temporal_doc [dom createDocument condition]
    set temporal_node [$temporal_doc documentElement]

    set temporal_if [$condition_node cloneNode -deep]
    $temporal_node appendChild $temporal_if    

    set then_node [$condition_node selectNodes { following-sibling::*[local-name()='then' and position()=1] } ]
    if { [llength $then_node] != 1 } {
        return 0
    }
    set then_temporal_node [$then_node cloneNode -deep]
    $temporal_node appendChild $then_temporal_node

    set else_node [$condition_node selectNodes { following-sibling::*[local-name()='else' and position()=2] } ]
    if { [llength $else_node] == 1 } {
        set else_temporal_node [$else_node cloneNode -deep]
        $temporal_node appendChild $else_temporal_node       
    } elseif { [llength $else_node] > 1 } {
        return 0        
    }
    set xml_piece [$temporal_node asXML]
    
    set if_then_else_id [imsld::item_revision_new -attributes [list [list method_id $method_id] \
                                                                   [list condition_xml $xml_piece]] \
                             -content_type imsld_condition \
                             -parent_id $parent_id]
    return $if_then_else_id
}

ad_proc -public imsld::parse::parse_and_create_class { 
    -class_node
    -parent_id
    -method_id
} {
    Parse a class and stores all the information in the database.

    Returns the class_id (item_id) if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param method_id 
    @param class_node
    @param parent_id Parent folder ID
} {
    set class_identifier [imsld::parse::get_attribute -node $class_node -attr_name class]
    set class_id [imsld::item_revision_new -attributes [list [list identifier $class_identifier] \
                                                            [list method_id $method_id]] \
                      -content_type imsld_class \
                      -parent_id $parent_id]
}            

ad_proc -public imsld::parse::parse_and_create_calculate { 
    -calculate_node
    -manifest
    -manifest_id
    -parent_id
} {
    Parse a condition and stores all the information in the database.

    Returns a list with the condition_id (item_id) if there were no errors, or 0 and an explanation messge if there was an error.
    
    @param calculate_node The condition node to be parsed 
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param parent_id Parent folder ID
} {
    set calculate [$calculate_node asXML]
    set imsld_id [db_1row get_imsld_id {
        select ii.item_id 
        from imsld_imsldsi ii, imsld_organisationsi io
        where ii.organization_id = io.item_id
        and io.manifest_id = :manifest_id
        and content_revision__is_live(ii.imsld_id) = 't'
    }]
    set calculate_id [imsld::item_revision_new -attributes [list [list imsld_id $imsld_id] \
                                                                [list xml_piece $calculate]] \
                          -content_type imsld_expression \
                          -parent_id $parent_id]
    return $calculate_id
}

ad_proc -public imsld::parse::parse_and_create_imsld_manifest { 
    -xmlfile:required
    -manifest_id:required
    {-community_id ""}
    -tmp_dir:required
} {
    Parse a XML IMS LD file and store all the information found in the database, such as the manifest, the organization, the imsld with its components, method, activities, etc.

    Returns a list with the new manifest_id and the warnings, if thera are any, and if there was no errors. Otherwise it returns 0 and the error.
    
    @param xmlfile The file to parse. This file must be compliant with the IMS LD spec
    @param manifest_id The manifest_id that is being created
    @option community_id community_id of the community where the manifest and its contents will be created. Default value is
    @param tmp_dir tmp dir where the files were extracted to
} {
    set community_id [expr { [empty_string_p $community_id] ? [dotlrn_community::get_community_id] : $community_id }]
    set warnings ""

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
    set organizations [$manifest selectNodes {*[local-name()='organizations']}]

    imsld::parse::validate_multiplicity -tree $organizations -multiplicity 1 -element_name organizations -equal
    set organization_id [imsld::cp::organization_new -manifest_id $manifest_id -parent_id $cr_folder_id]

    # IMS-LD
    set imsld [$organizations selectNodes "*\[local-name()='learning-design'\]"]

    imsld::parse::validate_multiplicity -tree $imsld -multiplicity 1 -element_name IMD-LD -equal
    set imsld_title [imsld::parse::get_title -node $imsld -prefix imsld]
    set imsld_identifier [imsld::parse::get_attribute -node $imsld -attr_name identifier]
    set imsld_level [imsld::parse::get_attribute -node $imsld -attr_name level]
    set imsld_level [expr { [empty_string_p $imsld_level] ? "" : [string tolower $imsld_level] }]
    set imsld_version [imsld::parse::get_attribute -node $imsld -attr_name version]
    set imsld_sequence_p [imsld::parse::get_bool_attribute -node $imsld -attr_name sequence_used -default f]

    # IMS-LD: Learning Objectives (which are really an imsld_item that can have resource associated.)
    set learning_objectives [$imsld selectNodes "*\[local-name()='learning-objectives'\]"]
    if { [llength $learning_objectives] } {
        imsld::parse::validate_multiplicity -tree $learning_objectives -multiplicity 1 -element_name learning-objectives(ims-ld) -equal
        set learning_objective_list [imsld::parse::parse_and_create_learning_objective -learning_objective_node $learning_objectives \
                                         -manifest_id $manifest_id \
                                         -parent_id $cr_folder_id \
                                         -manifest $manifest \
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
    set prerequisites [$imsld selectNodes "*\[local-name()='prerequisites'\]"] 
    if { [llength $prerequisites] } {
        imsld::parse::validate_multiplicity -tree $prerequisites -multiplicity 1 -element_name prerequisites(ims-ld) -equal
        set prerequisite_list [imsld::parse::parse_and_create_prerequisite -prerequisite_node $prerequisites \
                                   -manifest_id $manifest_id \
                                   -manifest $manifest \
                                   -parent_id $cr_folder_id \
                                   -tmp_dir $tmp_dir]

        set prerequisite_id [lindex $prerequisite_list 0]
        if { !$prerequisite_id } {
            # there is an error, abort and return the list with the error
            return $prerequisite_list
        }
    } else {
        set prerequisite_id ""
    }

    # now that we have all the necessary information, let's create the imsld
    set imsld_id [imsld::item_revision_new -attributes [list [list identifier $imsld_identifier] \
                                                            [list level $imsld_level] \
                                                            [list version $imsld_version] \
                                                            [list sequence_p $imsld_sequence_p] \
                                                            [list learning_objective_id $learning_objective_id] \
                                                            [list prerequisite_id $prerequisite_id] \
                                                            [list organization_id $organization_id]] \
                      -content_type imsld_imsld \
                      -title $imsld_title \
                      -parent_id $cr_folder_id]

    # Components
    set components [$imsld selectNodes "*\[local-name()='components'\]"]
    imsld::parse::validate_multiplicity -tree $components -multiplicity 1 -element_name components -equal
    set component_id [imsld::item_revision_new -attributes [list [list imsld_id $imsld_id]] \
                          -content_type imsld_component \
                          -parent_id $cr_folder_id]

    # Components: Roles
    set roles [$components selectNodes "*\[local-name()='roles'\]"]
    imsld::parse::validate_multiplicity -tree $roles -multiplicity 1 -element_name roles -equal

    # Components: Roles: Learners    
    set learner_list [$roles selectNodes "*\[local-name()='learner'\]"]
    imsld::parse::validate_multiplicity -tree $learner_list -multiplicity 1 -element_name learners(roles) -greather_than

    foreach learner $learner_list {
        set learner_parse_list [imsld::parse::parse_and_create_role -role_type learner \
                                    -manifest $manifest \
                                    -manifest_id $manifest_id \
                                    -parent_id $cr_folder_id \
                                    -tmp_dir $tmp_dir \
                                    -roles_node $learner \
                                    -component_id $component_id]
        if { ![lindex $learner_parse_list 0] } {
            # an error happened, abort and return the list whit the error
            return $learner_parse_list
        }
    }

    # Components: Roles: Staff
    set staff_list [$roles selectNodes "*\[local-name()='staff'\]"]
    if { [llength $staff_list] } {
        foreach staff $staff_list {
            set staff_parse_list [imsld::parse::parse_and_create_role -role_type staff \
                                      -manifest $manifest \
                                      -manifest_id $manifest_id \
                                      -parent_id $cr_folder_id \
                                      -tmp_dir $tmp_dir \
                                      -roles_node $staff \
                                      -component_id $component_id]
            if { ![lindex $staff_parse_list 0] } {
                    # an error happened, abort and return the list whit the error
                return $staff_parse_list
            }
        }
    }

    # Components: Properties
    set properties [$components selectNodes "*\[local-name()='properties'\]"]
    if { [llength $properties] } {
        imsld::parse::validate_multiplicity -tree $properties -multiplicity 1 -element_name properties -equal
        foreach property $properties {
            set properties_list [imsld::parse::parse_and_create_property -property_node $property \
                                     -manifest $manifest \
                                     -manifest_id $manifest_id \
                                     -parent_id $cr_folder_id \
                                     -tmp_dir $tmp_dir \
                                     -component_id $component_id]
        }
    }

    # Components: Environments
    # The environments are parsed now, and not the activities, because the activities may reference
    # the environments so they have to be in the database already.

    set environment_component [$components selectNodes "*\[local-name()='environments'\]"]
    if { [llength $environment_component] } {
        imsld::parse::validate_multiplicity -tree $environment_component -multiplicity 1 -element_name environments -equal
        set environments [$environment_component selectNodes "*\[local-name()='environment'\]"]
        imsld::parse::validate_multiplicity -tree $environments -multiplicity 1 -element_name environments -greather_than
        foreach environment $environments {
            set environment_ref_list [imsld::parse::parse_and_create_environment -environment_node $environment \
                                          -component_id $component_id \
                                          -manifest_id $manifest_id \
                                          -manifest $manifest \
                                          -parent_id $cr_folder_id \
                                          -tmp_dir $tmp_dir]
            set environment_ref_id [lindex $environment_ref_list 0]
            if { !$environment_ref_id } {
                # there is an error, abort and return the list with the error
                return $environment_ref_list
            }
        }
    }
    
    # Componetns: Activities
    # N.B.: With the level C and notificaitons, it is possible to make a reference to an 'uncreated'
    #       learning or support activity. Therefore we must check before if the activity has not been created
    set activities [$components selectNodes "*\[local-name()='activities'\]"]
    if { [llength $activities] } {
        imsld::parse::validate_multiplicity -tree $activities -multiplicity 1 -element_name components -equal

        # Componets: Activities: Learning Activities
        set learning_activities [$activities selectNodes "*\[local-name()='learning-activity'\]"]
        imsld::parse::validate_multiplicity -tree $learning_activities -multiplicity 1 -element_name learning-activities -greather_than
        
        foreach learning_activity $learning_activities {
            set la_identifier [imsld::parse::get_attribute -node $learning_activity -attr_name identifier]
            
            if { ![db_0or1row already_crated_la_p {
                select 1
                from imsld_learning_activities
                where identifier = :la_identifier
                and component_id = :component_id
            }] } {
                set learning_activity_list [imsld::parse::parse_and_create_learning_activity -component_id $component_id \
                                                -activity_node $learning_activity \
                                                -manifest $manifest \
                                                -manifest_id $manifest_id \
                                                -parent_id $cr_folder_id \
                                                -tmp_dir $tmp_dir]
                if { ![lindex $learning_activity_list 0] } {
                    # an error happened, abort and return the list whit the error
                    return $learning_activity_list
                }
            }
        }

        # Componets: Activities: Support Activities
        set support_activities [$activities selectNodes "*\[local-name()='support-activity'\]"]
        
        foreach support_activity $support_activities {
            set sa_identifier [imsld::parse::get_attribute -node $support_activity -attr_name identifier]
            
            if { ![db_0or1row already_crated_sa_p {
                select 1
                from imsld_support_activities
                where identifier = :sa_identifier
                and component_id = :component_id
            }] } {
                set support_activity_list [imsld::parse::parse_and_create_support_activity -component_id $component_id \
                                               -activity_node $support_activity \
                                               -manifest $manifest \
                                               -manifest_id $manifest_id \
                                               -parent_id $cr_folder_id \
                                               -tmp_dir $tmp_dir]
                if { ![lindex $support_activity_list 0] } {
                    # an error happened, abort and return the list whit the error
                    return $support_activity_list
                }
            }
        }

        # Components: Activities: Activity Structures
        set actvity_structures [$activities selectNodes "*\[local-name()='activity-structure'\]"]
        foreach activity_structure $actvity_structures {
            set activity_structure_list [imsld::parse::parse_and_create_activity_structure -component_id $component_id \
                                             -activity_node $activity_structure \
                                             -manifest $manifest \
                                             -manifest_id $manifest_id \
                                             -parent_id $cr_folder_id \
                                             -tmp_dir $tmp_dir]
            if { ![lindex $activity_structure_list 0] } {
                    # an error happened, abort and return the list whit the error
                return $activity_structure_list
            }
        }
    }

    # Method
    set method [$imsld selectNodes "*\[local-name()='method'\]"]
    imsld::parse::validate_multiplicity -tree $method -multiplicity 1 -element_name method -equal

    # Method: Complete Unit of Learning
    set complete_unit_of_learning [$method selectNodes "*\[local-name()='complete-unit-of-learning'\]"]
    set complete_act_id ""
    set time_in_seconds ""
    set when_prop_value_is_set_xml ""
    if { [llength $complete_unit_of_learning] } {
        imsld::parse::validate_multiplicity -tree $complete_unit_of_learning -multiplicity 1 -element_name complete-unit-of-learning -equal
        
        # Method: Complete Unit of Learning: Time Limit
        set time_limit [$complete_unit_of_learning selectNodes "*\[local-name()='time-limit'\]"]
        if { [llength $time_limit] } {
            imsld::parse::validate_multiplicity -tree $time_limit -multiplicity 1 -element_name time-limit(complete-unit-of-learning) -equal
            set time_string [imsld::parse::get_element_text -node $time_limit]
            set time_in_seconds [imsld::parse::convert_time_to_seconds -time $time_string]
        }
        # Method: Complete Unit of Learning: When Property Value is Set
        set when_prop_value_is_set [$complete_unit_of_learning selectNodes "*\[local-name()='when-property-value-is-set'\]"] 
        if { [llength $when_prop_value_is_set] } {
            imsld::parse::validate_multiplicity -tree $when_prop_value_is_set -multiplicity 1 -element_name when-property-valye-is-set(complete-unit-of-learning) -equal
            # create a node where the when-property-value-is-set will be stored
            set temporal_doc [dom createDocument when-property-value-is-set]
            set temporal_node [$temporal_doc documentElement]
            
            $temporal_node appendChild $when_prop_value_is_set
            set when_prop_value_is_set_xml [$temporal_node asXML]
        }
        set complete_act_id [imsld::item_revision_new -attributes [list [list time_in_seconds $time_in_seconds] \
                                                                       [list when_prop_val_is_set_xml $when_prop_value_is_set_xml]] \
                                 -content_type imsld_complete_act \
                                 -parent_id $cr_folder_id]

        if { [llength $when_prop_value_is_set] } {
            #search properties in expression 
            set property_nodes_list [$when_prop_value_is_set selectNodes {.//*[local-name()='property-ref']}]
            foreach property $property_nodes_list {
                set property_id [imsld::get_property_item_id -identifier [$property getAttribute ref] -imsld_id [db_string get_imsld_id {select imsld_id from imsld_imsldsi where item_id = :imsld_id}]]
                # map the property with the complete_act_id
                relation_add imsld_prop_wpv_is_rel $property_id $complete_act_id
            }
        }
    }

    # Method: On Completion
    set on_completion [$method selectNodes "*\[local-name()='on-completion'\]"]
    set on_completion_id ""
    set change_property_value_xml ""
    if { [llength $on_completion] } {
        imsld::parse::validate_multiplicity -tree $on_completion -multiplicity 1 -element_name on-completion(method) -equal

        # Act: On Completion: Change Property Value
        set change_property_value_list [$on_completion selectNodes "*\[local-name()='change-property-value'\]"] 
        if { [llength $change_property_value_list] } {
            # create a node where all the change-property-values will be stored
            set temporal_doc [dom createDocument change-property-values]
            set temporal_node [$temporal_doc documentElement]
            
            $temporal_node appendChild $change_property_value_list
            set change_property_value_xml [$temporal_node asXML]
        }


        set feedback_desc [$on_completion selectNodes "*\[local-name()='feedback-description'\]"]
        if { [llength $feedback_desc] } {
            imsld::parse::validate_multiplicity -tree $feedback_desc -multiplicity 1 -element_name feedback(method) -equal
            set feedback_title [imsld::parse::get_title -node $feedback_desc -prefix imsld]
            set on_completion_id [imsld::item_revision_new -parent_id $cr_folder_id \
                                      -content_type imsld_on_completion \
                                      -attributes [list [list feedback_title $feedback_title]]]
            set feedback_items [$feedback_desc selectNodes "*\[local-name()='item'\]"]
            foreach feedback_item $feedback_items {
                set item_list [imsld::parse::parse_and_create_item -manifest $manifest \
                                   -manifest_id $manifest_id \
                                   -item_node $feedback_item \
                                   -parent_id $cr_folder_id \
                                   -tmp_dir $tmp_dir]
                set item_id [lindex $item_list 0]
                if { !$item_id } {
                    # an error happened, abort and return the list whit the error
                    return $item_list
                }
                # map item with the support objective
                relation_add imsld_feedback_rel $on_completion_id $item_id
            }
        } else {
            set on_completion_id [imsld::item_revision_new -parent_id $parent_id \
                                      -content_type imsld_on_completion]
        }
        
    }

    set method_id [imsld::item_revision_new -parent_id $cr_folder_id \
                       -content_type imsld_method \
                       -attributes [list [list imsld_id $imsld_id] \
                                        [list complete_act_id $complete_act_id] \
                                        [list on_completion_id $on_completion_id]]]

    # to avoid infinite loops, take the notifications parsing out
    if { [llength $on_completion] } {
        # Method: On Completion: Notifications
        set notifications_list [$on_completion selectNodes "*\[local-name()='notification'\]"] 
        if { [llength $notifications_list] } {
            foreach notification $notifications_list {
                set notification_list [imsld::parse::parse_and_create_notification -method_id $method_id \
                                           -notification_node $notification \
                                           -manifest $manifest \
                                           -manifest_id $manifest_id \
                                           -parent_id $cr_folder_id \
                                           -tmp_dir $tmp_dir]
                set notification_id [lindex $notification_list 0]
                if { !$notification_id } {
                    # an error occurred, return it
                    return $notification_list
                }
                # map on_completion with the notif
                relation_add imsld_on_comp_notif_rel $on_completion_id $notification_id
            }
        }
    }

    # Method: Plays
    set plays [$method selectNodes "*\[local-name()='play'\]"]
    imsld::parse::validate_multiplicity -tree $plays -multiplicity 1 -element_name plays -greather_than
    
    set count 1
    foreach play $plays {
        set play_list [imsld::parse::parse_and_create_play -method_id $method_id \
                           -play_node $play \
                           -manifest $manifest \
                           -manifest_id $manifest_id \
                           -parent_id $cr_folder_id \
                           -tmp_dir $tmp_dir \
                           -sort_order $count]
        if { ![lindex $play_list 0] } {
            # an error happened, abort and return the list whit the error
            return $play_list
        }
        incr count
    }

    # Method: Complete Method: When play comleted
    # The method is completed when the referenced plays are completed
    set complete_play [$method selectNodes "*\[local-name()='complete-unit-of-learning'\]"]
    if { [llength $complete_play] } {
        imsld::parse::validate_multiplicity -tree $complete_play -multiplicity 1 -element_name complete-play -equal
        set when_play_completed_list [$complete_play selectNodes "*\[local-name()='when-play-completed'\]"]
        foreach when_play_completed $when_play_completed_list {
            set ref [imsld::parse::get_attribute -node $when_play_completed -attr_name ref]
            # verify that the referenced play exists
            if { ![db_0or1row get_rp_id {
                select item_id as play_id 
                from imsld_playsi 
                where identifier = :ref 
                and content_revision__is_live(play_id) = 't' 
                and method_id = :method_id
            } ] } {
                return [list 0 "[_ imsld.lt_The_referenced_play_i]"]
            }
            # found, map the play (with the imsld_mp_completed_rel) with the method
            relation_add imsld_mp_completed_rel $method_id $play_id
        }
    }

    # Method: Conditions
    set conditions_list [$method selectNodes "*\[local-name()='conditions'\]"]
    foreach conditions $conditions_list {
        if {[llength $conditions]} {
            set imsld_ifs_list [$conditions selectNodes { *[local-name()='if'] } ]

            foreach imsld_if $imsld_ifs_list {
                
                set condition_id [imsld::parse::parse_and_create_if_then_else -condition_node $imsld_if \
                                      -manifest_id $manifest_id \
                                      -parent_id $cr_folder_id \
                                      -manifest $manifest \
                                      -method_id $method_id ]
        
                #search condition properties
                set property_nodes_list [$imsld_if selectNodes {.//*[local-name()='property-ref'] }]
                foreach property $property_nodes_list {

                    set property_id [imsld::get_property_item_id -identifier [$property getAttribute ref] -imsld_id $imsld_id]
                    relation_add imsld_prop_cond_rel $property_id $condition_id 
                }
                #search condition roles
                #search conditional imsld learning materials
                set ilm_condition_node_list [$imsld_if selectNodes {.//*[local-name()='complete']/*}]

                foreach ilm_condition_node $ilm_condition_node_list {
                    set ref [$ilm_condition_node getAttribute ref]
                    set node_name [$ilm_condition_node localName]

                    switch $node_name {
                        learning-activity-ref {
                            db_1row get_la_item_id {
                                                   select ila.item_id as ilm_item_id 
                                                   from imsld_learning_activitiesi ila, 
                                                        imsld_componentsi ici 
                                                   where ila.identifier=:ref
                                                         and ila.component_id=ici.item_id 
                                                         and ici.imsld_id=:imsld_id
                            }
                        }
                        support-activity-ref {
                            db_1row get_sa_item_id {
                                                    select ila.item_id as ilm_item_id 
                                                    from imsld_support_activitiesi ila, 
                                                         imsld_componentsi ici 
                                                    where ila.identifier=:ref 
                                                          and ila.component_id=ici.item_id 
                                                          and ici.imsld_id=:imsld_id
                            }
                        }
                        activity-structure-ref {
                            db_1row get_as_item_id {
                                                    select ila.item_id as ilm_item_id
                                                    from imsld_activity_structuresi ila, 
                                                         imsld_componentsi ici 
                                                    where ila.identifier=:ref
                                                          and ila.component_id=ici.item_id 
                                                          and ici.imsld_id=:imsld_id
                            }
                        }
                        unit-of-learning-href {

                        }
                        role-part-ref {
                            db_1row get_role_part_item_id {
                                                    select irp.item_id as ilm_item_id
                                                    from imsld_role_partsi irp, 
                                                         imsld_actsi ia,
                                                         imsld_playsi ipi,
                                                         imsld_methodsi imi 
                                                    where irp.identifier=:ref 
                                                          and irp.act_id=ia.item_id  
                                                          and ia.play_id=ipi.item_id 
                                                          and ipi.method_id=imi.item_id 
                                                          and imi.imsld_id=:imsld_id
                            }
                        }
                        act-ref {
                            db_1row get_act_item_id {
                                                    select ia.item_id as ilm_item_id 
                                                    from imsld_actsi ia,
                                                         imsld_playsi ipi,
                                                         imsld_methodsi imi 
                                                    where ia.identifier=:ref 
                                                          and ia.play_id=ipi.item_id 
                                                          and ipi.method_id=imi.item_id 
                                                          and imi.imsld_id=:imsld_id
                            }

                        }
                        play-ref {
                            db_1row get_play_item_id {
                                                    select ip.item_id as ilm_item_id
                                                    from imsld_playsi ip,
                                                         imsld_methodsi imi 
                                                    where ip.identifier=:ref
                                                          and ip.method_id=imi.item_id 
                                                          and imi.imsld_id=:imsld_id;
                            }
                        }
                    }
                    relation_add imsld_ilm_cond_rel $ilm_item_id $condition_id
                }
            }
        }
    }

    # Classes: since the class elements are 'global-elements', we have to searh for the class elements
    #          through the entire manifest. 
    # NOTE: The classes are initialized to "is-visible = false"
    set classes [$method selectNodes "//*\[local-name()='class'\]"]
    foreach class_node $classes {
        # Check the base URI
        set class_identifier [imsld::parse::get_attribute -node $class_node -attr_name class]
        if { [string eq [$class_node namespaceURI] [imsld::parse::get_URI -type "imsld"]] && ![db_0or1row class_created_p { *SQL* }] } {
            # it's an ims-ld class, store it
            set class_id [imsld::parse::parse_and_create_class -class_node $class_node \
                              -method_id $method_id \
                              -parent_id $cr_folder_id]
        }
    }

    # Resources
    # look for the resource in the manifest and add it to the CR
    set manifest_resources_list [$manifest selectNodes {*[local-name()='resources']}]
    set resources_list [$manifest_resources_list selectNodes {*[local-name()='resource']}]

    foreach resource_left $resources_list {
        set resource_identifier [imsld::parse::get_attribute -node $resource_left -attr_name identifier]
        # the resource can't be duplicated
        if { ![db_0or1row already_created_p {
            select 1 from imsld_cp_resources where identifier = :resource_identifier and manifest_id = :manifest_id
        }] } {
            imsld::parse::validate_multiplicity -tree $resource_left -multiplicity 1 -element_name "resources (cp resources)" -equal
            set resource_list [imsld::parse::parse_and_create_resource -resource_node $resource_left \
                                   -manifest $manifest \
                                   -manifest_id $manifest_id \
                                   -parent_id $cr_folder_id \
                                   -tmp_dir $tmp_dir]
            set resource_id [lindex $resource_list 0]
            if { !$resource_id } {
                # return the error
                return $resource_list
            }
        }
    }
    
    if { ![empty_string_p $warnings] } {
        set warnings "[_ imsld.lt_br__Warnings_ul_warni]"
    }
    return [list $manifest_id "$warnings"]
}

