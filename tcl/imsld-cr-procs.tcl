# /packages/imsld/tcl/imsld-cr-procs.tcl

ad_library {
    Procedures in the imsld namespace that interact with the cr.
    
    @creation-date Jul 2005
    @author jopez@inv.it.uc3m.es
    @cvs-id $Id$
}

namespace eval imsld {}
namespace eval imsld::cr {}

ad_proc -public imsld::cr::folder_new {
    -folder_name:required
    {-parent_id ""}
    {-folder_label ""}
    {-folder_id ""}
} {
    Adds the folder to the CR. Returns the folder_id

    @param folder_name Name of the folder
    @option parent_id Parent ID Folder where the folder will be created
    @option label Label for the folder to create
    @option folder_id folder_id. Default value is [db_nextval "acs_object_id_seq"]
} {
    # gets the user_id and IP
    set user_id [ad_conn user_id]
    set creation_ip [ad_conn peeraddr]
    set folder_id [expr { [empty_string_p $folder_id] ? [db_nextval "acs_object_id_seq"] : $folder_id }]

    set folder_label [expr { [empty_string_p $folder_label] ? $folder_name : $folder_label }]

    db_transaction {
        # create the folder
        set folder_id [content::folder::new -folder_id $folder_id \
                           -name $folder_name \
                           -parent_id $parent_id \
                           -creation_user $user_id \
                           -creation_ip $creation_ip \
                           -label $folder_label]
        content::folder::register_content_type -folder_id $folder_id -content_type content_revision -include_subtypes t
        content::folder::register_content_type -folder_id $folder_id -content_type content_folder -include_subtypes t
        content::folder::register_content_type -folder_id $folder_id -content_type  content_extlink -include_subtypes t
        content::folder::register_content_type -folder_id $folder_id -content_type content_simlink -include_subtypes t
        permission::grant -party_id $user_id -object_id $folder_id -privilege admin
    } on_error {
        ad_return_error "<#_ Error creating folder #>" "<#_ There was an error creating the folder. Aborting. #> <pre>$errmsg</pre>"
        ad_script_abort
    }
    return $folder_id
}

ad_proc -public imsld::cr::file_new {
    -href
    -path_to_file
    -file_name
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id
    {-mime_type "text/plain"}
    {-storage_type "lob"}
} {
    Creates a new file in the file storage. Returns the item_id for that file.

    @param href href of the file (the path to the item in the file system)
    @param path_to_file path to file in the fs
    @param file_name file name
    @option item_id Item_id of the file. [db_nextval "acs_object_id_seq"] used by default.
    @option title Title of the file.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the file. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the file. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the file. [dt_sysdate] used by default.
    @option edit Are we editing the file?
    @param parent_id Identifier of the parent folder
} {
    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_cp_file
    set item_name "${item_id}_imsld_cp_file"
    set title [expr { [empty_string_p $title] ? $item_name : $title }]

    if { !$edit_p } {
        # create

        # double-click protection
        set file_exists_p [db_0or1row file_exists {
            select 1 
            from imsld_cp_files icf, cr_items cri
            where cri.item_id = :item_id 
            and cri.live_revision = icf.imsld_file_id}]

        if { !$file_exists_p } {
            set item_id [content::item::new -item_id $item_id \
                             -name $file_name \
                             -content_type $content_type \
                             -parent_id $parent_id \
                             -creation_user $user_id \
                             -creation_ip $creation_ip \
                             -mime_type $mime_type \
                             -storage_type $storage_type \
                             -context_id $package_id]
        }
    }
    
    set revision_id [content::revision::new -item_id $item_id \
                         -title $file_name \
                         -content_type $content_type \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -item_id $item_id \
                         -mime_type $mime_type \
                         -is_live "t" \
                         -attributes [list [list path_to_file $path_to_file] \
                                          [list file_name $file_name] \
                                          [list href $href]]]
    
    return $item_id
}
