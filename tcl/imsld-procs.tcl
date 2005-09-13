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

ad_proc -public imsld::rel_type_delete { 
    -rel_type:required
} { 
    Deletes a rel type (since the rel_types does not have a delete proc)
} {  

    db_1row select_type_info {
        select t.table_name 
        from acs_object_types t
        where t.object_type = :rel_type
    }
    
    set rel_id_list [db_list select_rel_ids {
        select r.rel_id
        from acs_rels r
        where r.rel_type = :rel_type
    }]
    
    # delete all relations and drop the relationship
    # type. 
    
    db_transaction {
        foreach rel_id $rel_id_list {
            relation_remove $rel_id
        }
        
        db_exec_plsql drop_relationship_type {
            BEGIN
            acs_rel_type.drop_type( rel_type  => :rel_type,
                                    cascade_p => 't' );
            END;
        }
    } on_error {
        ad_return_error "Error deleting relationship type" "We got the following error trying to delete this relationship type:<pre>$errmsg</pre>"
        ad_script_abort
    }
    # If we successfully dropped the relationship type, drop the table.
    # Note that we do this outside the transaction as it commits all
    # transactions anyway
    if { [db_table_exists $table_name] } {
        db_exec_plsql drop_type_table "drop table $table_name"
    }
} 

ad_proc -public imsld::imsld_new {
    -identifier
    {-item_id ""}
    {-title ""}
    {-level ""}
    {-version ""}
    -sequence_p
    {-learning_objective_id ""}
    {-prerequisite_id ""}
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
                         -attributes [list [list identifier [string tolower $identifier]] \
                                          [list version $version] \
                                          [list level $level] \
                                          [list sequence_p $sequence_p] \
                                          [list learning_object_id $learning_object_id] \
                                          [list prerequisite_id $prerequisite_id]]]
    
    return $item_id
}

ad_proc -public imsld::learning_objective_new {
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
                         -attributes [list [list pretty_title $title]]]
    
    return $item_id
}

ad_proc -public imsld::prerequisite_new {
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id:required
} {
    Creates a new prerequisite for the given imsld_id.

    @option item_id Item_id of the prerequisite. [db_nextval "acs_object_id_seq"] used by default.
    @option title Title of the prerequisite.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the prerequisite. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the prerequisite. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the prerequisite. [dt_sysdate] used by default.
    @option edit Are we editing the prerequiste?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_prerequisite
    set item_name "${item_id}_imsld_prerequisite"
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
                         -attributes [list [list pretty_title $pretty_title]]]
    
    return $item_id
}

ad_proc -public imsld::activity_description_new {
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id:required
} {
    Creates a new activity description for the given imsld_id.

    @option item_id Item_id of the activity description. [db_nextval "acs_object_id_seq"] used by default.
    @option title Title of the activity description.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the activity description. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the activity description. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the activity description. [dt_sysdate] used by default.
    @option edit Are we editing the prerequiste?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_activity_description
    set item_name "${item_id}_imsld_activity_description"
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
                         -attributes [list [list pretty_title $pretty_title]]]
    
    return $item_id
}

ad_proc -public imsld::_new {
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id:required
} {
    Creates a new activity description for the given imsld_id.

    @option item_id Item_id of the activity description. [db_nextval "acs_object_id_seq"] used by default.
    @option title Title of the activity description.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the activity description. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the activity description. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the activity description. [dt_sysdate] used by default.
    @option edit Are we editing the prerequiste?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_activity_description
    set item_name "${item_id}_imsld_activity_description"
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
                         -attributes [list [list pretty_title $pretty_title]]]
    
    return $item_id
}

ad_proc -public imsld::item_new {
    -identifier
    {-identifierref ""}
    {-is_visible_p t}
    {-parameters ""}
    {-parent_item_id ""}
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id:required
} {
    Creates a new item for the given imsld_id.

    @param identifier Item identifier in the manifest.
    @option identifierref A reference to a <resource> identifier (within the same package).
    @option is_visible_p Initial visibility value of the item. Defaults to true.
    @option parameters Parameters to be passed during runtime.
    @option parent_item_id In case it's a nested item. Default null
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
                         -attributes [list [list identifier [string tolower $identifier]] \
                                          [list identifierref $identifierref] \
                                          [list is_visible_p $is_visible_p] \
                                          [list parameters $parameters] \
                                          [list parent_item_id $parent_item_id]]]
    
    return $item_id
}

ad_proc -public imsld::component_new {
    -imsld_id
    {-item_id ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id:required
} {
    Creates a new component for the given imsld_id.

    @param imsld_id imsld_id of the imsld that this component belongs to.
    @option item_id Item_id of the component. [db_nextval "acs_object_id_seq"] used by default.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the component. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the component. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the component. [dt_sysdate] used by default.
    @option edit Are we editing the prerequiste?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_component
    set item_name "${item_id}_imsld_component"

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
                         -attributes [list [list imsld_id $imsld_id]]]
    
    return $item_id
}

ad_proc -public imsld::role_new {
    -component_id
    -identifier
    {-parent_role_id ""}
    -role_type
    -create_new_p
    {-match_persons_p 0}
    {-max_persons ""}
    {-min_persons ""}
    {-href ""}
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id:required
} {
    Creates a new role.

    @param component_id component_id of the component wich this role belongs to.
    @param identifier Role identifier in the manifest.
    @option parent_role_id role_id of the parent role (in case this is a nested role).
    @param role_type staff or learner
    @param create_new_p Can users with this role create other roles? true for allowed and false for not allowed.
    @option max_persons
    @option min_persons
    @option href
    @option item_id Item_id of the role. [db_nextval "acs_object_id_seq"] used by default.
    @option title Title of the item.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the role. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the role. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the role. [dt_sysdate] used by default.
    @option edit Are we editing the prerequiste?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_role
    set item_name "${item_id}_imsld_role"
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
                         -title $item_name \
                         -content_type $content_type \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -item_id $item_id \
                         -is_live "t" \
                         -attributes [list [list component_id $component_id] \
                                          [list identifier [string tolower $identifier]] \
                                          [list parent_role_id $parent_role_id] \
                                          [list role_tye $role_type] \
                                          [list create_new_p $create_new_p] \
                                          [list max_persons $max_persons] \
                                          [list min_persons $min_persons] \
                                          [list href $href]]]
    return $item_id
}

ad_proc -public imsld::learning_object_new {
    -environment_id
    {-class ""}
    -identifier
    -is_visible_p
    {-parameters ""}
    {-type ""}
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id:required
} {
    Creates a new learning object.

    @param environment_id Environment where to which learning object belongs
    @option class 
    @param identifier Learning object identifier
    @param is_visible_p Initial visibility attribute
    @option parameters Parameters to be passed during runtime
    @option type The type of learning object
    @option item_id Item_id of the learning_object. [db_nextval "acs_object_id_seq"] used by default.
    @option title Title of the item.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the learning object. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the learning object. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the learning object. [dt_sysdate] used by default.
    @param edit Are we editing the prerequiste?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_learning_object
    set item_name "${item_id}_imsld_learning_object"
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
                         -title $item_name \
                         -content_type $content_type \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -item_id $item_id \
                         -is_live "t" \
                         -attributes [list [list class $class] \
                                          [list environment_id $environment_id] \
                                          [list is_visible_p $-is_visible_p] \
                                          [list type $type] \
                                          [list identifier [string tolower $identifier]] \
                                          [list parameters $parameters]]]
    return $item_id
}

ad_proc -public imsld::service_new {
    -environment_id
    {-class ""}
    -identifier
    -is_visible_p
    {-parameters ""}
    -service_type
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id:required
} {
    Creates a new service.

    @param environment_id Environment where to which service belongs
    @option class 
    @param identifier service identifier
    @param is_visible_p Initial visibility attribute
    @option parameters Parameters to be passed during runtime
    @param service_type The type of service
    @option item_id Item_id of the service. [db_nextval "acs_object_id_seq"] used by default.
    @option title Title of the item.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the service. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the service. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the service. [dt_sysdate] used by default.
    @param edit Are we editing the prerequiste?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_service
    set item_name "${item_id}_imsld_service"
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
                         -title $item_name \
                         -content_type $content_type \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -item_id $item_id \
                         -is_live "t" \
                         -attributes [list [list class $class] \
                                          [list environment_id $environment_id] \
                                          [list is_visible_p $-is_visible_p] \
                                          [list service_type $type] \
                                          [list identifier [string tolower $identifier]] \
                                          [list parameters $parameters]]]
    return $item_id
}

ad_proc -public imsld::send_mail_service_new {
    -service_id
    -is_visible_p
    {-parameters ""}
    -recipients
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id:required
} {
    Creates a new send mail serivce.

    @param service_id service where to which send mail service belongs
    @param is_visible_p Initial visibility attribute
    @option parameters Parameters to be passed during runtime
    @param recipients Select:  'all-persons-in-role' or 'persons-in-role'
    @option item_id Item_id of the send mail serivce. [db_nextval "acs_object_id_seq"] used by default.
    @option title Title of the item.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the send mail serivce. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the send mail serivce. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the send mail serivce. [dt_sysdate] used by default.
    @param edit Are we editing the prerequiste?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_send_mail_service
    set item_name "${item_id}_imsld_send_mail_service"
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
                         -title $item_name \
                         -content_type $content_type \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -item_id $item_id \
                         -is_live "t" \
                         -attributes [list [list class $class] \
                                          [list service_id $service_id] \
                                          [list recipients $recipients] \
                                          [list is_visible_p $-is_visible_p] \
                                          [list parameters $parameters]]]
    return $item_id
}

ad_proc -public imsld::send_mail_data_new {
    -send_mail_service_id
    -role_id
    {-mail_data ""}
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id:required
} {
    Creates a new send mail data

    @param send_mail_service_id send mail service to which send mail data belongs
    @param role_id
    @option mail_data
    @option item_id Item_id of the send mail data. [db_nextval "acs_object_id_seq"] used by default.
    @option title Title of the item.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the send mail data. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the send mail data. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the send mail data. [dt_sysdate] used by default.
    @param edit Are we editing the send mail data?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_send_mail_service
    set item_name "${item_id}_imsld_send_mail_service"
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
                         -title $item_name \
                         -content_type $content_type \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -item_id $item_id \
                         -is_live "t" \
                         -attributes [list [list -send_mail_service_id -send_mail_service_id] \
                                          [list -role_id -role_id] \
                                          [list -mail_data -mail_data]]]
    return $item_id
}

ad_proc -public imsld::conference_service_new {
    -service_id
    -manager_id
    {-imsld_item_id ""}
    -conference_type
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id:required
} {
    Creates a new conference service

    @param service_id Service to which conference service belongs
    @param manager_id role_id of the conference manager
    @option item_id Item_id of the conference service. [db_nextval "acs_object_id_seq"] used by default.
    @option title Title of the item.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the conference service. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the conference service. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the conference service. [dt_sysdate] used by default.
    @param edit Are we editing the conference service?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_conference_service
    set item_name "${item_id}_imsld_conference_service"
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
                         -title $item_name \
                         -content_type $content_type \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -item_id $item_id \
                         -is_live "t" \
                         -attributes [list [list -send_mail_service_id -send_mail_service_id] \
                                          [list -role_id -role_id] \
                                          [list -mail_data -mail_data]]]
    return $item_id
}

ad_proc -public imsld::environment_new {
    -component_id
    -identifier
    {-learning_object_id ""}
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id:required
} {
    Creates a new environment

    @param component_id Component id of the one that owns the environment.
    @param identifier Unique identifier in the manifest.
    @option learning_object_id In case the environment has one.
    @option item_id Item_id of the environment. [db_nextval "acs_object_id_seq"] used by default.
    @option title Title of the item.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the environment. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the environment. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the environment. [dt_sysdate] used by default.
    @param edit Are we editing the environment?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_environment
    set item_name "${item_id}_imsld_environment"
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
                         -title $item_name \
                         -content_type $content_type \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -item_id $item_id \
                         -is_live "t" \
                         -attributes [list [list -component_id $component_id] \
                                          [list -identifier $identifier] \
                                          [list -learning_object_id $learning_object_id]]]
    return $item_id
}

ad_proc -public imsld::time_limit_new {
    -time_in_seconds
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id:required
} {
    Creates a new time limit

    @param time_in_seconds Amount of time in seconds
    @option item_id Item_id of the time limit. [db_nextval "acs_object_id_seq"] used by default.
    @option title Title of the item.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the time limit. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the time limit. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the time limit. [dt_sysdate] used by default.
    @param edit Are we editing the time limit?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_time_limit
    set item_name "${item_id}_imsld_time_limit"
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
                         -title $item_name \
                         -content_type $content_type \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -item_id $item_id \
                         -is_live "t" \
                         -attributes [list [list -time_in_seconds]]]
    return $item_id
}

ad_proc -public imsld::on_completion_new {
    -feedback_title
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id:required
} {
    Creates a new on completion

    @param feedback_title
    @option item_id Item_id of the on completion. [db_nextval "acs_object_id_seq"] used by default.
    @option title Title of the item.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the on completion. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the on completion. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the on completion. [dt_sysdate] used by default.
    @param edit Are we editing the on completion?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_on_completion
    set item_name "${item_id}_imsld_on_completion"
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
                         -title $item_name \
                         -content_type $content_type \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -item_id $item_id \
                         -is_live "t" \
                         -attributes [list [list -feedback_title $feedback_title]]]
    return $item_id
}

ad_proc -public imsld::learning_activity_new {
    -identifier
    -component_id
    {-parameters ""}
    -is_visible_p
    -user_choice_p
    {-time_limit_id ""}
    {-on_completion_id ""}
    {-learning_objective_id ""}
    {-prerequisite_id ""}
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -parent_id:required
} {
    Creates a new learning activity

    @param identifier learning activity unique identifier in the manifest
    @param component_id component_id where the activity belongs
    @option parameters Parameters to be passed during runtime
    @param is_visible_p Initial visibility attribute
    @param user_choice_p Will the learner decide when the activity ends?
    @option time_limt_id Possible time limit associated with the activity
    @option on_completion_id Learning activity actions to be executed after the activity is finished
    @option learning_objective_id  Possible learning objectives associated with the acitivty
    @option prerequisite_id Possible prerequisites associated with the acitivty
    @option item_id Item_id of the learning activity. [db_nextval "acs_object_id_seq"] used by default.
    @option title Title of the item.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the learning activity. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the learning activity. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the learning activity. [dt_sysdate] used by default.
    @param edit Are we editing the learning activity?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set content_type imsld_learning_activity
    set item_name "${item_id}_imsld_learning_activity"
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
                         -title $item_name \
                         -content_type $content_type \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -item_id $item_id \
                         -is_live "t" \
                         -attributes [list [list -identifier $identifier] \
                                          [list -component_id $component_id] \
                                          [list -parameters $parameters] \
                                          [list -is_visible_p $is_visible_p] \
                                          [list -user_choice_p $user_choice_p] \
                                          [list -time_limit_id $time_limit_id] \
                                          [list -on_completion_id $on_completion_id] \
                                          [list -learning_objective_id $learning_objective_id] \
                                          [list -prerequisite_id $prerequisite_id]]]
    return $item_id
}
