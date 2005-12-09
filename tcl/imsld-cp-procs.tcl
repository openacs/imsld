# /packages/imsld/tcl/imsld-cp-procs.tcl

ad_library {
    Procedures in the imsld namespace that have to do with Content Packagin.
    
    @creation-date Aug 2005
    @author jopez@inv.it.uc3m.es
    @cvs-id $Id$
}

namespace eval imsld {}
namespace eval imsld::cp {}

 # IMS CP database transaction functions

ad_proc -public imsld::cp::manifest_new {
    -identifier
    {-item_id ""}
    {-version "null"}
    {-parent_manifest_id ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    {-is_shared_p f}
    -edit:boolean
    -parent_id
} {
    Inserts a new manifest according to the imsmanifest.xml file.

    @param identifier intrinsic manifest identifier. 
    @option item_id Item_id of the manifest. [db_nextval "acs_object_id_seq"] used by default.
    @option version version.
    @option parent_manifest_id parent manifest id (for manifest with submanifests).
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the manifest. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the manifest. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the manifest. [dt_sysdate] used by default.
    @option is_shared_p Is this manifest shared?
    @option edit Are we editing the manifest?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set prent_manifest_id [expr { [empty_string_p $parent_manifest_id] ? 0 : $parent_manifest_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_cp_manifest 
    set item_name "${item_id}_[string tolower $identifier]"

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
                         -title $identifier \
                         -content_type $content_type \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -item_id $item_id \
                         -is_live "t" \
                         -attributes [list [list identifier $identifier] \
                                          [list version $version] \
                                          [list parent_manifest_id $parent_manifest_id] \
                                          [list is_shared_p $is_shared_p]]]
    
    return $item_id
}

ad_proc -public imsld::cp::organization_new {
    -manifest_id
    {-item_id ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    {-parent_id ""}
    -edit:boolean
} {
    Inserts a new organization in the database.

    @param manifest_id ID of the manifest which the organization is part of.
    @option item_id Item_id of the organization. [db_nextval "acs_object_id_seq"] used by default.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the organization. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the organization. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the organization. [dt_sysdate] used by default.
    @param parent_id Identifier of the parent folder
    @option edit Are we editing the organization?
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    if { [string eq "" $parent_id] } {
        set parent_id [content::item::get_id -item_path "cr_manifest_${manifest_id}" -resolve_index f] 
        if { [string eq "" $parent_id] } {
            return -code error "IMSLD::imsld::cp::organization_new: No parent folder for organization $item_id"
        }
    }

    set content_type imsld_cp_organization
    set item_name "${item_id}_organization"

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
                         -title $item_name \
                         -content_type $content_type \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -item_id $item_id \
                         -is_live "t" \
                         -attributes [list [list manifest_id $manifest_id]]]
    
    return $item_id
}

ad_proc -public imsld::cp::resource_new {
    -manifest_id
    -identifier
    -type
    {-href ""}
    {-item_id ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    {-acs_object_id ""}
    {-parent_id ""}
    -edit:boolean
} {
    Inserts a new organization in the database.

    @param manifest_id ID of the manifest which the resource is part of.
    @param identifier Resource identifier in the manifest.
    @param type A string that identifies the type of resource.
    @option href A reference to the "entry point" of this resource.
    @option item_id Item_id of the resource. [db_nextval "acs_object_id_seq"] used by default.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the resource. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the resource. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the resource. [dt_sysdate] used by default.
    @option acs_object_id object_id of the objec resource
    @param parent_id Identifier of the parent folder
    @option edit Are we editing the resource?
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    if { [empty_string_p $parent_id] } {
        set parent_id [content::item::get_id -item_path "cr_manifest_${manifest_id}" -resolve_index f] 
        if { [empty_string_p $parent_id] } {
            return -code error "IMSLD::imsld::cp::resource_new: No parent folder for organization $item_id"
        }
    }

    set content_type imsld_cp_resource
    set item_name "${item_id}_[string tolower $identifier]"

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
                         -title $item_name \
                         -content_type $content_type \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -item_id $item_id \
                         -is_live "t" \
                         -attributes [list [list manifest_id $manifest_id] \
                                          [list identifier $identifier] \
                                          [list type $type] \
                                          [list acs_object_id $acs_object_id] \
                                          [list href $href]]]
    
    return $item_id
}

ad_proc -public imsld::cp::dependency_new {
    -resource_id
    -identifierref
    {-item_id ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    {-parent_id ""}
    -edit:boolean
} {
    Inserts a new organization in the database.

    @param resource_id ID of the resource to which the dependency is part of.
    @param identifierref Pointer to a resource identifier in the manifest.
    @option item_id Item_id of the dependency. [db_nextval "acs_object_id_seq"] used by default.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the dependency. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the dependency. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the dependency. [dt_sysdate] used by default.
    @param parent_id Identifier of the parent folder
    @option edit Are we editing the dependency?
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    if { [empty_string_p $parent_id] } {
        set manifest_id [db_string get_manifest {
            select icr.manifest_id 
            from imsld_cp_resources icr, cr_items cri 
            where icr.resource_id = cri.live_revision
            and cri.item_id = :resource_id
        }]
        set parent_id [content::item::get_id -item_path "cr_manifest_${manifest_id}" -resolve_index f] 
        if { [empty_string_p $parent_id] } {
            return -code error "IMSLD::imsld::cp::dependency_new: No parent folder for organization $item_id"
        }
    }

    set content_type imsld_cp_dependency
    set item_name "${item_id}_imsld_cp_dependency"

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
                         -title $item_name \
                         -content_type $content_type \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -item_id $item_id \
                         -is_live "t" \
                         -attributes [list [list resource_id $resource_id] \
                                          [list identifierref $identifierref]]]
    
    return $item_id
}
