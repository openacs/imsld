
#Elementos en el content repository
# /packages/imsld/tcl/imsld-gsi-install-procs.tcl

ad_library {
    Callback library for GSI installing porpouses.
    
    @creation-date Nov 2008
    @author lfuente@it.uc3m.es
}

namespace eval imsld {}
namespace eval imsld::gsi::install {}
namespace eval imsld::gsi::uninstall {}

#Para cada tipo de item. Se crea el tipo y despues los atributos.
ad_proc -public imsld::gsi::install::do_install {
} {
    A wrapper for GSI installation methods
} {
    #initialize the cr
    imsld::gsi::install::init_cr_model

    #init acs_rels
    imsld::gsi::install::init_rels

    #initialize non cr model
    imsld::gsi::install::init_noncr_model
}

ad_proc -public imsld::gsi::uninstall::do_uninstall {
} {
    A wrapper for GSI uninstallation methods
} {
    #remove acs_rels
    imsld::gsi::uninstall::remove_rels

    #clean the content repository
    imsld::gsi::install::clean_cr
}

ad_proc -public imsld::gsi::install::init_cr_model {
} {
    Creates cr_item types that correspond to the GSI model
} {
    content::type::new -content_type imsld_gsi_service -supertype content_revision -pretty_name "GSI service" -pretty_plural "GSI services" -table_name imsld_gsi_services -id_column  gsi_service_id
    content::type::attribute::new -content_type imsld_gsi_service -attribute_name environment_id -datatype number -pretty_name "GSI environment ID" -column_spec "integer"
    content::type::attribute::new -content_type imsld_gsi_service -attribute_name gsi_tool_id -datatype number -pretty_name "GSI tool ID" -column_spec "integer"
    content::type::attribute::new -content_type imsld_gsi_service -attribute_name gsi_constraint_id -datatype number -pretty_name "GSI constraint ID" -column_spec "integer"
    content::type::attribute::new -content_type imsld_gsi_service -attribute_name identifier -datatype string -pretty_name "GSI service XML identifier" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_gsi_service -attribute_name is_visible_p -datatype string -pretty_name "Is GSI service visible?" -column_spec "varchar(1)"


    content::type::new -content_type imsld_gsi_alternative -supertype content_revision -pretty_name "GSI Alternative" -pretty_plural "GSI Alternatives" -table_name imsld_gsi_alternatives -id_column  gsi_alternative_id
    content::type::attribute::new -content_type imsld_gsi_alternative -attribute_name gsi_service_id -datatype number -pretty_name "GSI service ID" -column_spec "integer"
    
    content::type::attribute::new -content_type imsld_gsi_alternative -attribute_name service_ref -datatype string -pretty_name "GSI Service reference" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_gsi_alternative -attribute_name learning_object_ref -datatype string -pretty_name "Learning object reference" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_gsi_alternative -attribute_name alternative_order -datatype integer -pretty_name "Sort order of alternative" -column_spec "integer"


    content::type::new -content_type imsld_gsi_group -supertype content_revision -pretty_name "GSI group" -pretty_plural "GSI groups" -table_name imsld_gsi_groups -id_column  gsi_group_id
    content::type::attribute::new -content_type imsld_gsi_group -attribute_name identifier -datatype string -pretty_name "GSI group XML identifier" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_gsi_group -attribute_name gsi_service_id -datatype integer -pretty_name "GSI service ID" -column_spec "integer"


    content::type::new -content_type imsld_gsi_tool -supertype content_revision -pretty_name "GSI Tool" -pretty_plural "GSI Tools" -table_name imsld_gsi_tools -id_column  gsi_tool_id


    content::type::new -content_type imsld_gsi_permission -supertype content_revision -pretty_name "GSI Permission" -pretty_plural "GSI Permissions" -table_name imsld_gsi_permissions -id_column  gsi_permission_id
    content::type::attribute::new -content_type imsld_gsi_permission -attribute_name holder_id -datatype integer -pretty_name "Permission holder ID" -column_spec "integer"
    content::type::attribute::new -content_type imsld_gsi_permission -attribute_name action -datatype string -pretty_name "Action" -column_spec "varchar(10)"
    content::type::attribute::new -content_type imsld_gsi_permission -attribute_name data_type -datatype string -pretty_name "GSI data type" -column_spec "varchar(20)"
    content::type::attribute::new -content_type imsld_gsi_permission -attribute_name owner_id -datatype integer -pretty_name "GSI data owner ID" -column_spec "integer"


    content::type::new -content_type imsld_gsi_keyword -supertype content_revision -pretty_name "GSI keyword" -pretty_plural "GSI keywords" -table_name imsld_gsi_keywords -id_column  gsi_keyword_id
    content::type::attribute::new -content_type imsld_gsi_keyword -attribute_name value -datatype string -pretty_name "GSI keyword value" -column_spec "varchar(100)"


    content::type::new -content_type imsld_gsi_constraint -supertype content_revision -pretty_name "GSI constraint" -pretty_plural "GSI constraints" -table_name imsld_gsi_constraints -id_column  gsi_constraint_id
    content::type::attribute::new -content_type imsld_gsi_constraint -attribute_name start_date -datatype string -pretty_name "GSI constraint start date" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_gsi_constraint -attribute_name stop_date -datatype string -pretty_name "GSI constraint stop date" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_gsi_constraint -attribute_name multiplicity -datatype string -pretty_name "GSI constraint multiplicity" -column_spec "varchar(50)"


#    content::type::new -content_type imsld_gsi_trigger -supertype content_revision -pretty_name "GSI Trigger" -pretty_plural "GSI Triggers" -table_name imsld_gsi_triggers -id_column  gsi_trigger_id
#    content::type::attribute::new -content_type imsld_gsi_trigger -attribute_name trigger_type -datatype string -pretty_name "GSI trigger type" -column_spec "varchar(100)"


    content::type::new -content_type imsld_gsi_funct_usage -supertype content_revision -pretty_name "GSI function usage set" -pretty_plural "GSI function usage sets" -table_name imsld_gsi_funct_usage -id_column  gsi_funct_usage_id

    content::type::attribute::new -content_type imsld_gsi_funct_usage -attribute_name gsi_trigger_id -datatype number -pretty_name "GSI trigger ID" -column_spec "integer"
    content::type::attribute::new -content_type imsld_gsi_funct_usage -attribute_name gsi_constraint_id -datatype number -pretty_name "GSI constraint ID" -column_spec "integer"
    content::type::attribute::new -content_type imsld_gsi_funct_usage -attribute_name gsi_function_id -datatype number -pretty_name "GSI function ID" -column_spec "integer"


#    content::type::new -content_type imsld_gsi_function_param -supertype content_revision -pretty_name "GSI function parameter" -pretty_plural "GSI function parameters" -table_name imsld_gsi_function_params -id_column  gsi_function_param_id
#    content::type::attribute::new -content_type imsld_gsi_function_param -attribute_name gsi_function_id -datatype number -pretty_name "GSI function ID" -column_spec "integer"
#    content::type::attribute::new -content_type imsld_gsi_function_param -attribute_name param_name -datatype string -pretty_name "GSI parameter name" -column_spec "varchar(100)"
#
#
#    content::type::new -content_type imsld_gsi_function -supertype content_revision -pretty_name "GSI function" -pretty_plural "GSI functions" -table_name imsld_gsi_functions -id_column  gsi_function_id
#    content::type::attribute::new -content_type imsld_gsi_function -attribute_name function_name -datatype string -pretty_name "#imsld.asdf#" -column_spec "varchar(100)"

}


ad_proc -public imsld::gsi::install::init_rels {
} {
    Creates acs_rel types that correspond to the GSI model
} {
    rel_types::new imsld_gsi_trigger_const_rel "GSI Trigger - GSI Constraint rel" "GSI Trigger - GSI constraint rels"  \
                                                        content_item 0 {} \
                                                        content_item 0 {}

    rel_types::new imsld_gsi_tools_perm_rel "GSI Tool - GSI Permission rel" "GSI Tool - GSI Permission rels"  \
                                                        content_item 0 {} \
                                                        content_item 0 {}

#    rel_types::new imsld_gsi_tools_funct_rel  "GSI Tool - GSI Function rel" "GSI Tool - GSI Functions rels"  \
#                                                        content_item 0 {} \
#                                                        content_item 0 {}

    rel_types::new imsld_gsi_keywords_tools_rel "GSI Keyword - GSI Tool rel" "GSI Keyword - GSI Tool rels"  \
                                                        content_item 0 {} \
                                                        content_item 0 {}

    rel_types::new imsld_gsi_groups_roles_rel "GSI Group - Imsld role rel" "GSI Group - GSI role rels"  \
                                                        content_item 0 {} \
                                                        content_item 0 {}
}
ad_proc -public imsld::gsi::install::init_noncr_model {
} {
    Fill tables of elements that are not cr_item types
} {

#supported functions

    set deploy_id [db_nextval acs_object_id_seq]
    db_dml insert_deploy_function {INSERT INTO imsld_gsi_functions VALUES (:deploy_id,'deploy' )};
    set close_id [db_nextval acs_object_id_seq]
    db_dml insert_close_function {INSERT INTO imsld_gsi_functions VALUES (:close_id, 'close' )};
    #we will need this ID later
    set setvalues_id [db_nextval acs_object_id_seq]
    db_dml insert_setvalues_function {INSERT INTO imsld_gsi_functions VALUES (:setvalues_id,'set-values')};
    set modifypermissions_id [db_nextval acs_object_id_seq]
    db_dml insert_modifypermissions_function {INSERT INTO imsld_gsi_functions VALUES (:modifypermissions_id,'modify-permissions' )};

#defined params in supported functions
    set param_id [db_nextval acs_object_id_seq]
    db_dml insert_setvalues_params {INSERT INTO imsld_gsi_function_params VALUES (:param_id, :setvalues_id, 'mime-type')};
    set param_id [db_nextval acs_object_id_seq]
    db_dml insert_setvalues_params {INSERT INTO imsld_gsi_function_params VALUES (:param_id, :setvalues_id, 'item')};

#supported triggers
    set trigger_id [db_nextval acs_object_id_seq]
    db_dml insert_startup_trigger {INSERT INTO imsld_gsi_triggers VALUES (:trigger_id,'startup-action')}
    set trigger_id [db_nextval acs_object_id_seq]
    db_dml insert_finish_trigger {INSERT INTO imsld_gsi_triggers VALUES (:trigger_id,'finish-action')}
    set onComplete_id [db_nextval acs_object_id_seq]
    db_dml insert_finish_trigger {INSERT INTO imsld_gsi_triggers VALUES (:onComplete_id,'on-complete-action')}
    set onCondition_id [db_nextval acs_object_id_seq]
    db_dml insert_finish_trigger {INSERT INTO imsld_gsi_triggers VALUES (:onCondition_id,'on-condition-action')}

#defined params in supported functions
    set param_id [db_nextval acs_object_id_seq]
    db_dml insert_setvalues_trig_params {INSERT INTO imsld_gsi_trigger_params VALUES (:param_id, 'if',:onCondition_id)};
    set param_id [db_nextval acs_object_id_seq]
    db_dml insert_setvalues_trig_params {INSERT INTO imsld_gsi_trigger_params VALUES (:param_id, 'identifierref',:onComplete_id)};
}


ad_proc -public imsld::gsi::uninstall::remove_rels {
} {
    Remove acs_rel types that correspond to the GSI model
} {
    #Remove rel types
    imsld::rel_type_delete -rel_type imsld_gsi_trigger_const_rel
    imsld::rel_type_delete -rel_type imsld_gsi_tools_perm_rel
    imsld::rel_type_delete -rel_type imsld_gsi_tools_funct_rel
    imsld::rel_type_delete -rel_type imsld_gsi_keywords_tools_rel
    imsld::rel_type_delete -rel_type imsld_groups_roles_rel
}


ad_proc -public imsld::gsi::uninstall::clean_cr {
} {
    Clean GSI types in the content repository
} {
    #First, delete attributes (TODO)
    content::type::attribute::delete -content_type imsld_gsi_service
    content::type::attribute::delete -content_type imsld_gsi_service
    content::type::attribute::delete -content_type imsld_gsi_service
    content::type::attribute::delete -content_type imsld_gsi_service
    content::type::attribute::delete -content_type imsld_gsi_service
    content::type::attribute::delete -content_type imsld_gsi_alternative
    content::type::attribute::delete -content_type imsld_gsi_alternative
    content::type::attribute::delete -content_type imsld_gsi_alternative
    content::type::attribute::delete -content_type imsld_gsi_alternative
    content::type::attribute::delete -content_type imsld_gsi_group
    content::type::attribute::delete -content_type imsld_gsi_group
    content::type::attribute::delete -content_type imsld_gsi_permission
    content::type::attribute::delete -content_type imsld_gsi_permission
    content::type::attribute::delete -content_type imsld_gsi_permission
    content::type::attribute::delete -content_type imsld_gsi_permission
    content::type::attribute::delete -content_type imsld_gsi_permission
    content::type::attribute::delete -content_type imsld_gsi_keyword
    content::type::attribute::delete -content_type imsld_gsi_constraint
    content::type::attribute::delete -content_type imsld_gsi_constraint
    content::type::attribute::delete -content_type imsld_gsi_constraint
    content::type::attribute::delete -content_type imsld_gsi_trigger
    content::type::attribute::delete -content_type imsld_gsi_funct_usage
    content::type::attribute::delete -content_type imsld_gsi_funct_usage
    content::type::attribute::delete -content_type imsld_gsi_funct_usage
    content::type::attribute::delete -content_type imsld_gsi_funct_usage
    content::type::attribute::delete -content_type imsld_gsi_function_params
    content::type::attribute::delete -content_type imsld_gsi_function_params
    content::type::attribute::delete -content_type imsld_gsi_function

    #Second, delete types
    content::type::delete -content_type imsld_gsi_service 
    content::type::delete -content_type imsld_gsi_alternative
    content::type::delete -content_type imsld_gsi_group
    content::type::delete -content_type imsld_gsi_tool
    content::type::delete -content_type imsld_gsi_permission
    content::type::delete -content_type imsld_gsi_data
    content::type::delete -content_type imsld_gsi_keyword
    content::type::delete -content_type imsld_gsi_constraint
    content::type::delete -content_type imsld_gsi_trigger
    content::type::delete -content_type imsld_gsi_funct_usage
    content::type::delete -content_type imsld_gsi_function_param
    content::type::delete -content_type imsld_gsi_function
}

