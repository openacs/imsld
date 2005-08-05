# /packages/imsld/tcl/imsld-procs.tcl

ad_library {
    Procedures in the imsld namespace.
    
    @creation-date Aug 2005
    @author jopez@inv.it.uc3m.es
    @cvs-id $Id$
}

namespace eval imsld {}

ad_proc -public imsld::safe_url_name { 
    -name:required
} { 
    returns the filename replacing some characters
} {  
    regsub -all {[<>:\"|/@\\\#%&+\\ ,\?]} $name {_} name
    return $name
} 

ad_proc -public imsld::imsld_new {
    -identifier
    {-item_id ""}
    {-title ""}
    {-level ""}
    {-version ""}
    -sequence_p
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id
} {
    Inserts a new manifest according to the imsmanifest.xml file.

    @param identifier intrinsic manifest identifier. 
    @option item_id Item_id of the imsld. [db_nextval "acs_object_id_seq"] used by default.
    @option title Title of the IMS-LD.
    @option version version.
    @param sequence_p Indicates if the imsld uses simple sequencing (true if yes, false otherwise)
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the imsld. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the imsld. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the imsld. [dt_sysdate] used by default.
    @option edit Are we editing the manifest?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_imsld
    set item_name "${item_id}_[string tolower $identifier]"
    set title [expr { [empty_string_p $title] ? $item_name : $title }]

    if { !$edit_p } {
        # create
        set item_id [content::item::new -item_id $item_id \
                         -name $item_name \
                         -content_type $content_type \
                         -parent_id $parent_id \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -context_id $package_id]
    }
    
    set revision_id [content::revision::new -item_id $item_id \
                         -title $title \
                         -content_type $content_type \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -item_id $item_id \
                         -is_live "t" \
                         -attributes [list [list identifier $identifier] \
                                          [list version $version] \
                                          [list level $level] \
                                          [list sequence_p $sequence_p]]]
    
    return $item_id
}

ad_proc -public imsld::learning_objective_new {
    -imsld_id
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id:required
} {
    Creates a new learning objective for the given imsld_id.

    @param imsld_id imsld_id of the imsld that this learning objective belongs to.
    @option item_id Item_id of the learning objective. [db_nextval "acs_object_id_seq"] used by default.
    @option title Title of the learning objective.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the learning objective. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the learning objective. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the learning objective. [dt_sysdate] used by default.
    @option edit Are we editing the learning object?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_learning_objective
    set item_name "${item_id}_imsld_learning_objective"
    set title [expr { [empty_string_p $title] ? $item_name : $title }]

    if { !$edit_p } {
        # create
        set item_id [content::item::new -item_id $item_id \
                         -name $item_name \
                         -content_type $content_type \
                         -parent_id $parent_id \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -context_id $package_id]
    }
    
    set revision_id [content::revision::new -item_id $item_id \
                         -title $title \
                         -content_type $content_type \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -item_id $item_id \
                         -is_live "t" \
                         -attributes [list [list imsld_id $imsld_id]]]
    
    return $item_id
}

ad_proc -public imsld::item_new {
    -identifier
    {-identifierref ""}
    {-is_visible_p t}
    {-parameters ""}
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id:required
} {
    Creates a new learning objective for the given imsld_id.

    @param identifier Item identifier in the manifest.
    @option identifierref A reference to a <resource> identifier (within the same package).
    @option is_visible_p Initial visibility value of the item. Defaults to true.
    @option parameters Parameters to be passed during runtime.
    @option item_id Item_id of the item. [db_nextval "acs_object_id_seq"] used by default.
    @option title Title of the item.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the item. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the item. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the item. [dt_sysdate] used by default.
    @option edit Are we editing the item?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_item
    set item_name "${item_id}_[string tolower $identifier]"
    set title [expr { [empty_string_p $title] ? $item_name : $title }]

    if { !$edit_p } {
        # create
        set item_id [content::item::new -item_id $item_id \
                         -name $item_name \
                         -content_type $content_type \
                         -parent_id $parent_id \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -context_id $package_id]
    }
    
    set revision_id [content::revision::new -item_id $item_id \
                         -title $title \
                         -content_type $content_type \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -item_id $item_id \
                         -is_live "t" \
                         -attributes [list [list identifier $identifier] \
                                          [list identifierref $identifierref] \
                                          [list is_visible_p $is_visible_p] \
                                          [list parameters $parameters]]]
    
    return $item_id
}

