# /packages/imsld/tcl/imsld-install-procs.tcl

ad_library {
    Callback library for installing porpouses.
    
    @creation-date Jul 2005
    @author jopez@inv.it.uc3m.es
    @cvs-id $Id$
}

namespace eval imsld {}
namespace eval imsld::install {}
namespace eval imsld::uninstall {}

ad_proc -public imsld::install::init_content_repository {  
} { 
    Creates content types and attributes
} { 

    ### IMS-LD
    # learning objects
    content::type::new -content_type imsld_learning_object -supertype content_revision -pretty_name "<#_ Learning Object #>" -pretty_plural "<#_ Learning Objects #>" -table_name imsld_learning_objects -id_column learning_object_id
    
    content::type::attribute::new -content_type imsld_learning_object -attribute_name identifier -datatype string -pretty_name "<#_ Identifier #>" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_learning_object -attribute_name class -datatype string -pretty_name "<#_ Class #>" -column_spec "varchar(4000)"
    content::type::attribute::new -content_type imsld_learning_object -attribute_name is_visible_p -datatype string -pretty_name "<#_ Is Visible? #>" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_learning_object -attribute_name type -datatype string -pretty_name "<#_ Type #>" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_learning_object -attribute_name parameters -datatype string -pretty_name "<#_ Parameters #>" -column_spec "varchar(4000)"
    
    # imsld 
    content::type::new -content_type imsld_imsld -supertype content_revision -pretty_name "<#_ IMS-LD #>" -pretty_plural "<#_ IMS-LDs #>" -table_name imsld_imslds -id_column imsld_id 

    content::type::attribute::new -content_type imsld_imsld -attribute_name identifier -datatype string -pretty_name "<#_ Identifier #>" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_imsld -attribute_name version -datatype string -pretty_name "<#_ Version #>" -column_spec "varchar(10)"
    content::type::attribute::new -content_type imsld_imsld -attribute_name level -datatype string -pretty_name "<#_ Level #>" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_imsld -attribute_name sequence_used_p -datatype string -pretty_name "<#_ Sequence Used #>" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_imsld -attribute_name learning_objective_id -datatype number -pretty_name "<#_ Learning Objectives ID #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_imsld -attribute_name prerequisite_id -datatype number -pretty_name "<#_ Prerequistes ID #>" -column_spec "integer"

    # learning objectives
    content::type::new -content_type imsld_learning_objective -supertype content_revision -pretty_name "<#_ IMS-LD Learning Objective #>" -pretty_plural "<#_ IMS-LD Learning Objectives #>" -table_name imsld_learning_objectives -id_column learning_object_id

    content::type::attribute::new -content_type imsld_learning_objective -attribute_name pretty_title -datatype string -pretty_name "<#_ Pretty Title #>" -column_spec "varchar(200)"

    # imsld prerequisites
    content::type::new -content_type imsld_prerequisite -supertype content_revision -pretty_name "<#_ IMS-LD Prerequisite #>" -pretty_plural "<#_ IMS-LD Prerequisites #>" -table_name imsld_prerequisites -id_column prerequisite_id

    content::type::attribute::new -content_type imsld_prerequisite -attribute_name pretty_title -datatype string -pretty_name "<#_ Pretty Title #>" -column_spec "varchar(200)"

    # imsld items
    content::type::new -content_type imsld_item -supertype content_revision -pretty_name "<#_ IMS-LD Item #>" -pretty_plural "<#_ IMS-LD Items #>" -table_name imsld_items -id_column imsld_item_id

    content::type::attribute::new -content_type imsld_item -attribute_name parent_item_id -datatype integer -pretty_name "<#_ Parent Item Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_item -attribute_name identifier -datatype string -pretty_name "<#_ Identifier #>" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_item -attribute_name identifierref -datatype string -pretty_name "<#_ Identifier Reference #>" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_item -attribute_name is_visible_p -datatype string -pretty_name "<#_ Is Visible? #>" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_item -attribute_name parameters -datatype string -pretty_name "<#_ Parameters #>" -column_spec "varchar(4000)"

    # components
    content::type::new -content_type imsld_component -supertype content_revision -pretty_name "<#_ IMS-LD Component #>" -pretty_plural "<#_ IMS-LD Components #>" -table_name imsld_components -id_column component_id

    content::type::attribute::new -content_type imsld_component -attribute_name imsld_id -datatype number -pretty_name "<#_ IMS-LD Identifier #>" -column_spec "integer"
    
    # imsld roles
    content::type::new -content_type imsld_role -supertype content_revision -pretty_name "<#_ IMS-LD Role #>" -pretty_plural "<#_ IMS-LD Roles #>" -table_name imsld_roles -id_column role_id

    content::type::attribute::new -content_type imsld_role -attribute_name component_id -datatype string -pretty_name "<#_ Component Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role -attribute_name identifier -datatype string -pretty_name "<#_ Identifier #>" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_role -attribute_name role_type -datatype string  -pretty_name "<#_ Role Type #>" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_role -attribute_name parent_role_id -datatype number -pretty_name "<#_ Parent Role Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role -attribute_name create_new_p -datatype string -pretty_name "<#_ Create New? #>" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_role -attribute_name match_persons_p -datatype string -pretty_name "<#_ Match Persons? #>" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_role -attribute_name max_persons -datatype number -pretty_name "<#_ Max Persons #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role -attribute_name min_persons -datatype number -pretty_name "<#_ Min Persons#>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role -attribute_name href -datatype string -pretty_name "<#_ Href #>" -column_spec "varchar(2000)"

    # imsld activity description
    content::type::new -content_type imsld_activity_desc -supertype content_revision -pretty_name "<#_ IMS-LD Activity Description #>" -pretty_plural "<#_ IMS-LD Activity Descriptions #>" -table_name imsld_activity_desc -id_column description_id

    content::type::attribute::new -content_type imsld_activity_desc -attribute_name pretty_title -datatype string -pretty_name "<#_ Pretty Title #>" -column_spec "varchar(200)"

    # learning activities
    content::type::new -content_type imsld_learning_activity -supertype content_revision -pretty_name "<#_ IMS-LD Learning Activity #>" -pretty_plural "<#_ IMS-LD Learning Activities #>" -table_name imsld_learning_activities -id_column activity_id
    
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name identifier -datatype string -pretty_name "<#_ Identifier #>" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name component_id -datatype number -pretty_name "<#_ Component Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name activity_description_id -datatype number -pretty_name "<#_ Activity Description Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name is_visible_p -datatype string -pretty_name "<#_ Is Visible? #>" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name user_choice_p -datatype string -pretty_name "<#_ User Choice? #>" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name time_limit_id -datatype number -pretty_name "<#_ Time Limit Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name on_completion_id -datatype number -pretty_name "<#_ On Completion Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name parameters -datatype string -pretty_name "<#_ Parameters #>" -column_spec "varchar(4000)"
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name learning_objective_id -datatype number -pretty_name "<#_ Learning Objective ID #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name prerequisite_id -datatype number -pretty_name "<#_ Prerequistes ID #>" -column_spec "integer"

    # support activities
    content::type::new -content_type imsld_support_activity -supertype content_revision -pretty_name "<#_ IMS-LD Support Activity #>" -pretty_plural "<#_ IMS-LD Support Activities #>" -table_name imsld_support_activities -id_column activity_id
    
    content::type::attribute::new -content_type imsld_support_activity -attribute_name identifier -datatype string -pretty_name "<#_ Identifier #>" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_support_activity -attribute_name component_id -datatype number -pretty_name "<#_ Component Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_support_activity -attribute_name parameter_id -datatype number -pretty_name "<#_ Parameter Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_support_activity -attribute_name is_visible_p -datatype string -pretty_name "<#_ Is Visible? #>" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_support_activity -attribute_name user_choice_p -datatype string -pretty_name "<#_ User Choice? #>" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_support_activity -attribute_name time_limit_id -datatype number -pretty_name "<#_ Time Limit Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_support_activity -attribute_name on_completion_id -datatype number -pretty_name "<#_ On Completion Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_support_activity -attribute_name parameters -datatype string -pretty_name "<#_ Parameters #>" -column_spec "varchar(4000)"

    # activity structures
    content::type::new -content_type imsld_activity_structure -supertype content_revision -pretty_name "<#_ IMS-LD Activity Structure #>" -pretty_plural "<#_ IMS-LD Activity Structures #>" -table_name imsld_activity_structures -id_column structure_id 

    content::type::attribute::new -content_type imsld_activity_structure -attribute_name component_id -datatype number -pretty_name "<#_Component Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_activity_structure -attribute_name identifier -datatype string -pretty_name "<#_ Identifier #>" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_activity_structure -attribute_name number_to_select -datatype number -pretty_name "<#_ Number to Select #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_activity_structure -attribute_name structure_type -datatype string -pretty_name "<#_ Structure Type #>" -column_spec "char(9)"
    content::type::attribute::new -content_type imsld_activity_structure -attribute_name sort -datatype string -pretty_name "<#_ Sort #>" -column_spec "varchar(4)"

    # environments
    content::type::new -content_type imsld_environment -supertype content_revision -pretty_name "<#_ IMD-LD Environment #>" -pretty_plural "<#_ IMD-LD Environments #>" -table_name imsld_environments -id_column environment_id
    
    content::type::attribute::new -content_type imsld_environment -attribute_name component_id -datatype number -pretty_name "<#_ Component Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_environment -attribute_name identifier -datatype string -pretty_name "<#_ Identifier #>" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_environment -attribute_name learning_object_id -datatype number -pretty_name "<#_ Learning Object Identifier #>" -column_spec "integer"

    # services
    content::type::new -content_type imsld_service -supertype content_revision -pretty_name "<#_ IMS-LD Service #>" -pretty_plural "<#_ IMS-LD Services #>" -table_name imsld_services -id_column service_id
    
    content::type::attribute::new -content_type imsld_service -attribute_name environment_id -datatype number -pretty_name "<#_ Environment Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_service -attribute_name identifier -datatype string -pretty_name "<#_ Identifier #>" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_service -attribute_name class -datatype string -pretty_name "<#_ Class #>" -column_spec "varchar(4000)"
    content::type::attribute::new -content_type imsld_service -attribute_name is_visible_p -datatype string -pretty_name "<#_ Is Visible? #>" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_service -attribute_name parameters -datatype string -pretty_name "<#_ Parameters #>" -column_spec "varchar(4000)"
    content::type::attribute::new -content_type imsld_service -attribute_name service_type -datatype string -pretty_name "<#_ Service Type #>" -column_spec "varchar(10)"

    # send mail services
    content::type::new -content_type imsld_send_mail_service -supertype content_revision -pretty_name "<#_ IMS-LD Sendmail Service #>" -pretty_plural "<#_ IMS-LD Sendmail Services #>" -table_name imsld_send_mail_services -id_column mail_id
    
    content::type::attribute::new -content_type imsld_send_mail_service -attribute_name service_id -datatype number -pretty_name "<#_ Service Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_send_mail_service -attribute_name recipients -datatype string -pretty_name "<#_ Recipients #>" -column_spec "varchar(11)"
    content::type::attribute::new -content_type imsld_send_mail_service -attribute_name is_visible_p -datatype string -pretty_name "<#_ Is Visible? #>" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_send_mail_service -attribute_name parameters -datatype string -pretty_name "<#_ Parameters #>" -column_spec "varchar(4000)"

    # send mail data
    content::type::new -content_type imsld_send_mail_data -supertype content_revision -pretty_name "<#_ IMS-LD Sendmail Data #>" -pretty_plural "<#_ IMS-LD Sendmail Data #>" -table_name imsld_send_mail_data -id_column data_id

    content::type::attribute::new -content_type imsld_send_mail_data -attribute_name send_mail_id -datatype number -pretty_name "<#_ Sendmail Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_send_mail_data -attribute_name role_id -datatype number -pretty_name "<#_ Role Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_send_mail_data -attribute_name mail_data -datatype string -pretty_name "<#_ Mail Data #>" -column_spec "varchar(4000)"

    # conference services
    content::type::new -content_type imsld_conference_service -supertype content_revision -pretty_name "<#_ IMS-LD Conference Service #>" -pretty_plural "<#_ IMS-LD Conference Services #>" -table_name imsld_conference_services -id_column conference_id

    content::type::attribute::new -content_type imsld_conference_service -attribute_name service_id -datatype number -pretty_name "<#_ Service Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_conference_service -attribute_name conference_type -datatype string -pretty_name "<#_ Conference Type #>" -column_spec "char(12)"
    content::type::attribute::new -content_type imsld_conference_service -attribute_name imsld_item_id -datatype number -pretty_name "<#_ Item Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_conference_service -attribute_name manager_id -datatype number -pretty_name "<#_ Manager Identifier #>" -column_spec "integer"

    # methods
    content::type::new -content_type imsld_method -supertype content_revision -pretty_name "<#_ IMS-LD Method #>" -pretty_plural "<#_ IMS-LD Methods #>" -table_name imsld_methods -id_column method_id
    
    content::type::attribute::new -content_type imsld_method -attribute_name imsld_id -datatype number -pretty_name "<#_ IMS-LD Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_method -attribute_name time_limit_id -datatype number -pretty_name "<#_ Time Limit Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_method -attribute_name on_completion_id -datatype number -pretty_name "<#_ On Completion Identifier #>" -column_spec "integer"

    # plays
    content::type::new -content_type imsld_play -supertype content_revision -pretty_name "<#_ IMS-LD Play #>" -pretty_plural "<#_ IMS-LD Plays #>" -table_name imsld_plays -id_column play_id

    content::type::attribute::new -content_type imsld_play -attribute_name method_id -datatype number -pretty_name "<#_ Method Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_play -attribute_name is_visible_p -datatype string -pretty_name "<#_ Is Visible? #>" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_play -attribute_name identifier -datatype string -pretty_name "<#_ Identifier #>" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_play -attribute_name when_last_act_completed_p -datatype string -pretty_name "<#_ When Last Act Completed? #>" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_play -attribute_name time_limit_id -datatype number -pretty_name "<#_ Time Limit Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_play -attribute_name on_completion_id -datatype number -pretty_name "<#_ On Completion Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_play -attribute_name sort_order -datatype number -pretty_name "<#_ Sort Order #>" -column_spec "integer"
    
    # acts
    content::type::new -content_type imsld_act -supertype content_revision -pretty_name "<#_ IMS-LD Act #>" -pretty_plural "<#_ IMS-LD Acts #>" -table_name imsld_acts -id_column act_id

    content::type::attribute::new -content_type imsld_act -attribute_name play_id -datatype number -pretty_name "<#_ Play Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_act -attribute_name time_limit_id -datatype number -pretty_name "<#_ Time Limit Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_act -attribute_name identifier -datatype string -pretty_name "<#_ Identifier #>" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_act -attribute_name on_completion_id -datatype number -pretty_name "<#_ On Completion Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_act -attribute_name sort_order -datatype number -pretty_name "<#_ Sort Order #>" -column_spec "integer"

    # role parts
    content::type::new -content_type imsld_role_part -supertype content_revision -pretty_name "<#_ IMS-LD Role Part #>" -pretty_plural "<#_ IMS-LD Role Parts #>" -table_name imsld_role_parts -id_column role_part_id

    content::type::attribute::new -content_type imsld_role_part -attribute_name act_id -datatype number -pretty_name "<#_ Act Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role_part -attribute_name identifier -datatype string -pretty_name "<#_ Identifier #>" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_role_part -attribute_name role_id -datatype number -pretty_name "<#_ Role Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role_part -attribute_name learning_activity_id -datatype number -pretty_name "<#_ Learning Activity Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role_part -attribute_name support_activity_id -datatype number -pretty_name "<#_ Support Activity Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role_part -attribute_name activity_structure_id -datatype number -pretty_name "<#_ Activity Structure Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role_part -attribute_name environment_id -datatype number -pretty_name "<#_ Environment Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role_part -attribute_name sort_order -datatype number -pretty_name "<#_ Sort Order #>" -column_spec "integer"

    # time limits
    content::type::new -content_type imsld_time_limit -supertype content_revision -pretty_name "<#_ IMS-LD Time Limit #>" -pretty_plural "<#_ IMS-LD Time Limits #>" -table_name imsld_time_limits -id_column time_limit_id
    
    content::type::attribute::new -content_type imsld_time_limit -attribute_name time_in_seconds -datatype number -pretty_name "<#_ Time in Seconds #>" -column_spec "integer"

    # on completion
    content::type::new -content_type imsld_on_completion -supertype content_revision -pretty_name "<#_ IMS-LD On Completion #>" -pretty_plural "<#_ IMS-LD On Completions #>" -table_name imsld_on_completion -id_column on_completion_id

    content::type::attribute::new -content_type imsld_on_completion -attribute_name feedback_title -datatype string -pretty_name "<#_ Feedbach Title #>" -column_spec "varchar(200)"

    ### IMS-LD Content Packaging

    # manifests
    content::type::new -content_type imsld_cp_manifest -supertype content_revision -pretty_name "<#_ IMS-LD CP Manifest #>" -pretty_plural "<#_ IMS-LD CP Manifests #>" -table_name imsld_cp_manifests -id_column manifest_id

    content::type::attribute::new -content_type imsld_cp_manifest -attribute_name identifier -datatype string -pretty_name "<#_ Identifier #>" -column_spec "varchar(1000)"
    content::type::attribute::new -content_type imsld_cp_manifest -attribute_name version -datatype string -pretty_name "<#_ Version #>" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_cp_manifest -attribute_name parent_manifest_id -datatype number -pretty_name "<#_ Parent Manifest Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_cp_manifest -attribute_name is_shared_p -datatype string -pretty_name "<#_ Is shared? #>" -column_spec "char(1)"

    # organizations
    content::type::new -content_type imsld_cp_organization -supertype content_revision -pretty_name "<#_ IMS-LD CP Organization #>" -pretty_plural "<#_ IMS-LD CP Organizations #>" -table_name imsld_cp_organizations -id_column organization_id
    
    content::type::attribute::new -content_type imsld_cp_organization -attribute_name manifest_id -datatype number -pretty_name "<#_ Manifest Identifier #>" -column_spec "integer"

    # resources
    content::type::new -content_type imsld_cp_resource -supertype content_revision -pretty_name "<#_ IMS-LD CP Resource #>" -pretty_plural "<#_ IMS-LD CP Resources #>" -table_name imsld_cp_resources -id_column resource_id

    content::type::attribute::new -content_type imsld_cp_resource -attribute_name manifest_id -datatype number -pretty_name "<#_ Manifest Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_cp_resource -attribute_name identifier -datatype string -pretty_name "<#_ Identifier #>" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_cp_resource -attribute_name type -datatype string -pretty_name "<#_ Type #>" -column_spec "varchar(1000)"
    content::type::attribute::new -content_type imsld_cp_resource -attribute_name href -datatype string -pretty_name "<#_ Href #>" -column_spec "varchar(2000)"

    # dependencies
    content::type::new -content_type imsld_cp_dependency -supertype content_revision -pretty_name "<#_ IMS-LD CP Dependency #>" -pretty_plural "<#_ IMS-LD CP Dependencies #>" -table_name imsld_cp_dependencies -id_column dependency_id

    content::type::attribute::new -content_type imsld_cp_dependency -attribute_name resource_id -datatype number -pretty_name "<#_ Resource Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_cp_dependency -attribute_name identifierref -datatype string -pretty_name "<#_ Identifierref #>" -column_spec "varchar(100)"

    # imsld cp files
    content::type::new -content_type imsld_cp_file -supertype content_revision -pretty_name "<#_ IMS-LD CP File #>" -pretty_plural "<#_ IMS-LD CP Filed #>" -table_name imsld_cp_files -id_column imsld_file_id

    content::type::attribute::new -content_type imsld_cp_file -attribute_name resource_id -datatype number -pretty_name "<#_ Resource Identifier #>" -column_spec "integer"
    content::type::attribute::new -content_type imsld_cp_file -attribute_name path_to_file -datatype string -pretty_name "<#_ Path to File #>" -column_spec "varchar(2000)"
    content::type::attribute::new -content_type imsld_cp_file -attribute_name file_name -datatype string -pretty_name "<#_ File name #>" -column_spec "varchar(2000)"
    content::type::attribute::new -content_type imsld_cp_file -attribute_name href -datatype string -pretty_name "<#_ Href #>" -column_spec "varchar(2000)"
    
}

ad_proc -public imsld::install::init_rels {  
} { 
    Create default rels between imsld items
} { 

    # Learing Objetcives - IMS-LD Items
    rel_types::new imsld_lo_item_rel "Learing Objective - Imsld Item rel" "Learing Objective - Imsld Item rels"  \
        content_item 0 {} \
        content_item 0 {}

    # Prerequisites - IMS-LD Items
    rel_types::new imsld_preq_item_rel "Prerequisite - Imsld Item rel" "Prerequisite - Imsld Item rels"  \
        content_item 0 {} \
        content_item 0 {}

    # IMS-LD Items - Resources (resource-ref)
    rel_types::new imsld_item_res_rel "Imsld Item - Resources rel" "Imsld Item - Resources rels"  \
        content_item 0 {} \
        content_item 0 {}

    # Role - IMS-LD Items
    rel_types::new imsld_role_item_rel "Role - Imslds Item rel" "Role - Imsld items rels"  \
        content_item 0 {} \
        content_item 0 {}

    # IMS-LD - Learning Objectives
    rel_types::new imsld_imsld_lob_rel "IMS-LD - Learning Objectives rel" "IMS-LD - Learning Objectives rels"  \
        content_item 0 {} \
        content_item 0 {}

    # Learning Object - IMS-LD Item
    rel_types::new imsld_l_object_item_rel "Learning Object - IMS-LD Item rel" "Learning Object - IMS-LD Item rels"  \
        content_item 0 {} \
        content_item 0 {}

    # Conference Service - Participants (role-ref)
    rel_types::new imsld_conf_part_rel "Conference Serice - Participants rel" "Conference Serice - Participants rels" \
        content_item 0 {} \
        content_item 0 {}

    # Conference Service - Observers (role-ref)
    rel_types::new imsld_conf_obser_rel "Conference Serice - Observers rel" "Conference Serice - Observers rels" \
        content_item 0 {} \
        content_item 0 {}

    # Conference Service - Moderators
    rel_types::new imsld_conf_moder_rel "Conference Serice - Moderators rel" "Conference Serice - Moderators rels" \
        content_item 0 {} \
        content_item 0 {}

    # Environment - Environment (environment-ref)
    rel_types::new imsld_env_env_rel "Environment - Environment rel" "Environment - Environment rels" \
        content_item 0 {} \
        content_item 0 {}

    # Activity Description - IMS-LD Items 
    rel_types::new imsld_actdesc_item_rel "Activity Description - Imsld Item rel" "Activity Description - Imsld Item rels"  \
        content_item 0 {} \
        content_item 0 {}

    # Learning Activity - Environment (environment-ref)
    rel_types::new imsld_la_env_rel "Learning Activity - Environment rel" "Learning Activity - Environment rels" \
        content_item 0 {} \
        content_item 0 {}

    # Support Activity - Environment (environment-ref)
    rel_types::new imsld_sa_env_rel "Support Activity - Environment rel" "Support Activity - Environment rels" \
        content_item 0 {} \
        content_item 0 {}

    # On Completion - Feedback
    rel_types::new imsld_feedback_rel "On Completion - Feedback rel" "On Completion - Feedback rels" \
        content_item 0 {} \
        content_item 0 {}

    # Support Activity - Role (role-ref)
    rel_types::new imsld_sa_role_rel "Support Activity - Role rel" "Support Activity - Role rels" \
        content_item 0 {} \
        content_item 0 {}

    # Activity Structure - Items (information)
    rel_types::new imsld_as_info_i_rel "Activity Structure - Item (information) rel" "Activity Structure - Item (information) rels" \
        content_item 0 {} \
        content_item 0 {}

    # Activity Structure - Environments (environment-ref)
    rel_types::new imsld_as_env_rel "Activity Structure - Environment (environment-ref) rel" "Activity Structure - Environment (environment-ref) rels" \
        content_item 0 {} \
        content_item 0 {}

    # Activity Structure - Learning Activities (learning-activity-ref)
    rel_types::new imsld_as_la_rel "Activity Structure - Learning Activities (learning-activity-ref) rel" "Activity Structure - Learning Activities (learning-activity-ref) rels" \
        content_item 0 {} \
        content_item 0 {}

    # Activity Structure - Support Activities (support-activity-ref)
    rel_types::new imsld_as_sa_rel "Activity Structure - Support Activities (support-activity-ref) rel" "Activity Structure - Support Activities (support-activity-ref) rels" \
        content_item 0 {} \
        content_item 0 {}

    # Activity Structure - Activity Structures (activity-structure-ref)
    rel_types::new imsld_as_as_rel "Activity Structure - Activity Structures (activity-structure-ref) rel" "Activity Structure - Activity Structures (activity-structure-ref) rels" \
        content_item 0 {} \
        content_item 0 {}

    # Act - Role Parts (when-role-part-completed)
    rel_types::new imsld_act_rp_completed_rel "Act - Role Parts (when-role-part-completed) rel" "Act - Role Parts (when-role-part-completed) rels" \
        content_item 0 {} \
        content_item 0 {}

    # Method - Plays (when-play-completed)
    rel_types::new imsld_mp_completed_rel "Method - Plays (when-play-completed) rel" "Method - Plays (when-play-completed) rels" \
        content_item 0 {} \
        content_item 0 {}

}

ad_proc -public imsld::uninstall::delete_rels {  
} { 
    Delete default rels between imsld items
} { 
    imsld::rel_type_delete -rel_type imsld_lo_item_rel
    imsld::rel_type_delete -rel_type imsld_preq_item_rel
    imsld::rel_type_delete -rel_type imsld_item_res_rel
    imsld::rel_type_delete -rel_type imsld_role_item_rel
    imsld::rel_type_delete -rel_type imsld_imsld_lob_rel
    imsld::rel_type_delete -rel_type imsld_l_object_item_rel
    imsld::rel_type_delete -rel_type imsld_conf_part_rel
    imsld::rel_type_delete -rel_type imsld_conf_obser_rel
    imsld::rel_type_delete -rel_type imsld_conf_moder_rel
    imsld::rel_type_delete -rel_type imsld_env_env_rel
    imsld::rel_type_delete -rel_type imsld_actdesc_item_rel
    imsld::rel_type_delete -rel_type imsld_la_env_rel
    imsld::rel_type_delete -rel_type imsld_sa_env_rel
    imsld::rel_type_delete -rel_type imsld_feedback_rel
    imsld::rel_type_delete -rel_type imsld_sa_role_rel
    imsld::rel_type_delete -rel_type imsld_as_info_i_rel
    imsld::rel_type_delete -rel_type imsld_as_env_rel
    imsld::rel_type_delete -rel_type imsld_as_la_rel
    imsld::rel_type_delete -rel_type imsld_as_sa_rel
    imsld::rel_type_delete -rel_type imsld_as_as_rel
    imsld::rel_type_delete -rel_type imsld_act_rp_completed_rel
    imsld::rel_type_delete -rel_type imsld_mp_completed_rel
}

ad_proc -public imsld::uninstall::empty_content_repository {  
} { 
    Deletes content types and attributes
} { 

    ### Attributes
    ### IMS-LD

    # learning objects
    content::type::attribute::delete -content_type imsld_learning_object -attribute_name identifier
    content::type::attribute::delete -content_type imsld_learning_object -attribute_name class
    content::type::attribute::delete -content_type imsld_learning_object -attribute_name is_visible_p
    content::type::attribute::delete -content_type imsld_learning_object -attribute_name type
    content::type::attribute::delete -content_type imsld_learning_object -attribute_name parameters

    # imsld
    content::type::attribute::delete -content_type imsld_imsld -attribute_name identifier
    content::type::attribute::delete -content_type imsld_imsld -attribute_name version
    content::type::attribute::delete -content_type imsld_imsld -attribute_name level
    content::type::attribute::delete -content_type imsld_imsld -attribute_name sequence_used_p
    content::type::attribute::delete -content_type imsld_imsld -attribute_name learning_objective_id
    content::type::attribute::delete -content_type imsld_imsld -attribute_name prerequisite_id

    # learning objectives
    content::type::attribute::delete -content_type imsld_learning_objective -attribute_name pretty_title

    # imsld prerequisites
    content::type::attribute::delete -content_type imsld_prerequisite -attribute_name pretty_title

    # imsld items
    content::type::attribute::delete -content_type imsld_item -attribute_name parent_item_id
    content::type::attribute::delete -content_type imsld_item -attribute_name identifier
    content::type::attribute::delete -content_type imsld_item -attribute_name identifierref
    content::type::attribute::delete -content_type imsld_item -attribute_name is_visible_p
    content::type::attribute::delete -content_type imsld_item -attribute_name parameters

    # componets
    content::type::attribute::delete -content_type imsld_component -attribute_name imsld_id

    # imsld roles
    content::type::attribute::delete -content_type imsld_role -attribute_name component_id
    content::type::attribute::delete -content_type imsld_role -attribute_name identifier
    content::type::attribute::delete -content_type imsld_role -attribute_name role_type
    content::type::attribute::delete -content_type imsld_role -attribute_name parent_role_id
    content::type::attribute::delete -content_type imsld_role -attribute_name create_new_p
    content::type::attribute::delete -content_type imsld_role -attribute_name match_persons_p
    content::type::attribute::delete -content_type imsld_role -attribute_name max_persons
    content::type::attribute::delete -content_type imsld_role -attribute_name min_persons
    content::type::attribute::delete -content_type imsld_role -attribute_name href

    # activity descriptions
    content::type::attribute::delete -content_type imsld_activity_desc -attribute_name pretty_title

    # learning activities
    content::type::attribute::delete -content_type imsld_learning_activity -attribute_name identifier
    content::type::attribute::delete -content_type imsld_learning_activity -attribute_name component_id
    content::type::attribute::delete -content_type imsld_learning_activity -attribute_name activity_description_id
    content::type::attribute::delete -content_type imsld_learning_activity -attribute_name is_visible_p
    content::type::attribute::delete -content_type imsld_learning_activity -attribute_name user_choice_p
    content::type::attribute::delete -content_type imsld_learning_activity -attribute_name time_limit_id
    content::type::attribute::delete -content_type imsld_learning_activity -attribute_name on_completion_id
    content::type::attribute::delete -content_type imsld_learning_activity -attribute_name parameters
    content::type::attribute::delete -content_type imsld_learning_activity -attribute_name learning_objective_id
    content::type::attribute::delete -content_type imsld_learning_activity -attribute_name prerequisite_id

    # support activities
    content::type::attribute::delete -content_type imsld_support_activity -attribute_name identifier
    content::type::attribute::delete -content_type imsld_support_activity -attribute_name component_id
    content::type::attribute::delete -content_type imsld_support_activity -attribute_name parameter_id
    content::type::attribute::delete -content_type imsld_support_activity -attribute_name is_visible_p
    content::type::attribute::delete -content_type imsld_support_activity -attribute_name user_choice_p
    content::type::attribute::delete -content_type imsld_support_activity -attribute_name time_limit_id
    content::type::attribute::delete -content_type imsld_support_activity -attribute_name on_completion_id
    content::type::attribute::delete -content_type imsld_support_activity -attribute_name parameters

    # activity structures
    content::type::attribute::delete -content_type imsld_activity_structure -attribute_name component_id
    content::type::attribute::delete -content_type imsld_activity_structure -attribute_name identifier
    content::type::attribute::delete -content_type imsld_activity_structure -attribute_name number_to_select
    content::type::attribute::delete -content_type imsld_activity_structure -attribute_name structure_type
    content::type::attribute::delete -content_type imsld_activity_structure -attribute_name sort

    # environments
    content::type::attribute::delete -content_type imsld_environment -attribute_name component_id
    content::type::attribute::delete -content_type imsld_environment -attribute_name identifier
    content::type::attribute::delete -content_type imsld_environment -attribute_name learning_object_id

    # send mail service
    content::type::attribute::delete -content_type imsld_service -attribute_name environment_id
    content::type::attribute::delete -content_type imsld_service -attribute_name identifier
    content::type::attribute::delete -content_type imsld_service -attribute_name class
    content::type::attribute::delete -content_type imsld_service -attribute_name is_visible_p
    content::type::attribute::delete -content_type imsld_service -attribute_name parameters
    content::type::attribute::delete -content_type imsld_service -attribute_name service_type

    # send mail service
    content::type::attribute::delete -content_type imsld_send_mail_service -attribute_name service_id
    content::type::attribute::delete -content_type imsld_send_mail_service -attribute_name recipients
    content::type::attribute::delete -content_type imsld_send_mail_service -attribute_name is_visible_p
    content::type::attribute::delete -content_type imsld_send_mail_service -attribute_name parameters

    # send mail data
    content::type::attribute::delete -content_type imsld_send_mail_data -attribute_name send_mail_id
    content::type::attribute::delete -content_type imsld_send_mail_data -attribute_name role_id
    content::type::attribute::delete -content_type imsld_send_mail_data -attribute_name mail_data
    
    # conference service
    content::type::attribute::delete -content_type imsld_conference_service -attribute_name service_id
    content::type::attribute::delete -content_type imsld_conference_service -attribute_name conference_type
    content::type::attribute::delete -content_type imsld_conference_service -attribute_name imsld_item_id
    content::type::attribute::delete -content_type imsld_conference_service -attribute_name manager_id
    
    # methods
    content::type::attribute::delete -content_type imsld_method -attribute_name imsld_id
    content::type::attribute::delete -content_type imsld_method -attribute_name time_limit_id
    content::type::attribute::delete -content_type imsld_method -attribute_name on_completion_id

    # plays
    content::type::attribute::delete -content_type imsld_play -attribute_name method_id
    content::type::attribute::delete -content_type imsld_play -attribute_name is_visible_p
    content::type::attribute::delete -content_type imsld_play -attribute_name identifier
    content::type::attribute::delete -content_type imsld_play -attribute_name when_last_act_completed_p
    content::type::attribute::delete -content_type imsld_play -attribute_name time_limit_id
    content::type::attribute::delete -content_type imsld_play -attribute_name on_completion_id
    content::type::attribute::delete -content_type imsld_play -attribute_name sort_order

    # acts
    content::type::attribute::delete -content_type imsld_act -attribute_name play_id
    content::type::attribute::delete -content_type imsld_act -attribute_name time_limit_id
    content::type::attribute::delete -content_type imsld_act -attribute_name identifier
    content::type::attribute::delete -content_type imsld_act -attribute_name on_completion_id
    content::type::attribute::delete -content_type imsld_act -attribute_name sort_order

    # role parts
    content::type::attribute::delete -content_type imsld_role_part -attribute_name act_id
    content::type::attribute::delete -content_type imsld_role_part -attribute_name identifier
    content::type::attribute::delete -content_type imsld_role_part -attribute_name role_id
    content::type::attribute::delete -content_type imsld_role_part -attribute_name learning_activity_id
    content::type::attribute::delete -content_type imsld_role_part -attribute_name support_activity_id
    content::type::attribute::delete -content_type imsld_role_part -attribute_name activity_structure_id
    content::type::attribute::delete -content_type imsld_role_part -attribute_name environment_id
    content::type::attribute::delete -content_type imsld_role_part -attribute_name sort_order

    # time limits
    content::type::attribute::delete -content_type imsld_time_limit -attribute_name time_in_seconds

    # on completion
    content::type::attribute::delete -content_type imsld_on_completion -attribute_name feedback_title
    
    ### IMS-LD Content Packaging
    
    # manifests
    content::type::attribute::delete -content_type imsld_cp_manifest -attribute_name identifier
    content::type::attribute::delete -content_type imsld_cp_manifest -attribute_name version
    content::type::attribute::delete -content_type imsld_cp_manifest -attribute_name parent_manifest_id
    content::type::attribute::delete -content_type imsld_cp_manifest -attribute_name is_shared_p

    # organizations
    content::type::attribute::delete -content_type imsld_cp_organization -attribute_name manifest_id

    # resources
    content::type::attribute::delete -content_type imsld_cp_resource -attribute_name manifest_id
    content::type::attribute::delete -content_type imsld_cp_resource -attribute_name identifier
    content::type::attribute::delete -content_type imsld_cp_resource -attribute_name type
    content::type::attribute::delete -content_type imsld_cp_resource -attribute_name href

    # dependencies
    content::type::attribute::delete -content_type imsld_cp_dependency -attribute_name resource_id
    content::type::attribute::delete -content_type imsld_cp_dependency -attribute_name identifierref

    # imsld cp files
    content::type::attribute::delete -content_type imsld_cp_file -attribute_name resource_id
    content::type::attribute::delete -content_type imsld_cp_file -attribute_name path_to_file
    content::type::attribute::delete -content_type imsld_cp_file -attribute_name file_name
    content::type::attribute::delete -content_type imsld_cp_file -attribute_name href

    ### Content Types
    ### IMS-LD
    content::type::delete -content_type imsld_learning_object -drop_table_p t 
    content::type::delete -content_type imsld_imsld -drop_table_p t
    content::type::delete -content_type imsld_learning_objective -drop_table_p t
    content::type::delete -content_type imsld_prerequisite -drop_table_p t
    content::type::delete -content_type imsld_item -drop_table_p t
    content::type::delete -content_type imsld_component -drop_table_p t
    content::type::delete -content_type imsld_role -drop_table_p t
    content::type::delete -content_type imsld_prerequisite -drop_table_p t
    content::type::delete -content_type imsld_activity_desc -drop_table_p t
    content::type::delete -content_type imsld_learning_activity -drop_table_p t
    content::type::delete -content_type imsld_support_activity -drop_table_p t
    content::type::delete -content_type imsld_activity_structure -drop_table_p t
    content::type::delete -content_type imsld_environment -drop_table_p t
    content::type::delete -content_type imsld_service -drop_table_p t
    content::type::delete -content_type imsld_send_mail_service -drop_table_p t
    content::type::delete -content_type imsld_send_mail_data -drop_table_p t
    content::type::delete -content_type imsld_conference_service -drop_table_p t
    content::type::delete -content_type imsld_method -drop_table_p t
    content::type::delete -content_type imsld_play -drop_table_p t
    content::type::delete -content_type imsld_act -drop_table_p t
    content::type::delete -content_type imsld_role_part -drop_table_p t
    content::type::delete -content_type imsld_time_limit -drop_table_p t
    content::type::delete -content_type imsld_on_completion -drop_table_p t

    ### IMS-LD Content Packaging
    content::type::delete -content_type imsld_cp_manifest -drop_table_p t
    content::type::delete -content_type imsld_cp_organization -drop_table_p t
    content::type::delete -content_type imsld_cp_resource -drop_table_p t
    content::type::delete -content_type imsld_cp_dependency -drop_table_p t
    content::type::delete -content_type imsld_cp_file -drop_table_p t
}

