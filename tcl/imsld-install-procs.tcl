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

    ### IMS-LD LEVEL A
    # learning objects
    content::type::new -content_type imsld_learning_object -supertype content_revision -pretty_name "#imsld.Learning_Object#" -pretty_plural "#imsld.Learning_Objects#" -table_name imsld_learning_objects -id_column learning_object_id
    
    content::type::attribute::new -content_type imsld_learning_object -attribute_name environment_id -datatype number -pretty_name "#imsld.lt_Environment_Identifie#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_learning_object -attribute_name identifier -datatype string -pretty_name "#imsld.Identifier#" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_learning_object -attribute_name class -datatype string -pretty_name "#imsld.Class#" -column_spec "varchar(4000)"
    content::type::attribute::new -content_type imsld_learning_object -attribute_name is_visible_p -datatype string -pretty_name "#imsld.Is_Visible#" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_learning_object -attribute_name type -datatype string -pretty_name "#imsld.Type#" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_learning_object -attribute_name parameters -datatype string -pretty_name "#imsld.Parameters#" -column_spec "varchar(4000)"
    
    # imsld 
    content::type::new -content_type imsld_imsld -supertype content_revision -pretty_name "#imsld.IMS-LD#" -pretty_plural "#imsld.IMS-LDs#" -table_name imsld_imslds -id_column imsld_id 

    content::type::attribute::new -content_type imsld_imsld -attribute_name organization_id -datatype number -pretty_name "#imsld.lt_Organization_Identifi#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_imsld -attribute_name identifier -datatype string -pretty_name "#imsld.Identifier#" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_imsld -attribute_name version -datatype string -pretty_name "#imsld.Version#" -column_spec "varchar(10)"
    content::type::attribute::new -content_type imsld_imsld -attribute_name level -datatype string -pretty_name "#imsld.Level#" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_imsld -attribute_name sequence_used_p -datatype string -pretty_name "#imsld.Sequence_Used#" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_imsld -attribute_name learning_objective_id -datatype number -pretty_name "#imsld.lt_Learning_Objectives_I#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_imsld -attribute_name prerequisite_id -datatype number -pretty_name "#imsld.Prerequistes_ID#" -column_spec "integer"

    # learning objectives
    content::type::new -content_type imsld_learning_objective -supertype content_revision -pretty_name "#imsld.lt_IMS-LD_Learning_Objec#" -pretty_plural "#imsld.lt_IMS-LD_Learning_Objec_1#" -table_name imsld_learning_objectives -id_column learning_objective_id

    content::type::attribute::new -content_type imsld_learning_objective -attribute_name pretty_title -datatype string -pretty_name "#imsld.Pretty_Title#" -column_spec "varchar(200)"

    # imsld prerequisites
    content::type::new -content_type imsld_prerequisite -supertype content_revision -pretty_name "#imsld.IMS-LD_Prerequisite#" -pretty_plural "#imsld.IMS-LD_Prerequisites#" -table_name imsld_prerequisites -id_column prerequisite_id

    content::type::attribute::new -content_type imsld_prerequisite -attribute_name pretty_title -datatype string -pretty_name "#imsld.Pretty_Title#" -column_spec "varchar(200)"

    # imsld items
    content::type::new -content_type imsld_item -supertype content_revision -pretty_name "#imsld.IMS-LD_Item#" -pretty_plural "#imsld.IMS-LD_Items#" -table_name imsld_items -id_column imsld_item_id

    content::type::attribute::new -content_type imsld_item -attribute_name parent_item_id -datatype integer -pretty_name "#imsld.lt_Parent_Item_Identifie#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_item -attribute_name identifier -datatype string -pretty_name "#imsld.Identifier#" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_item -attribute_name identifierref -datatype string -pretty_name "#imsld.Identifier_Reference#" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_item -attribute_name is_visible_p -datatype string -pretty_name "#imsld.Is_Visible#" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_item -attribute_name parameters -datatype string -pretty_name "#imsld.Parameters#" -column_spec "varchar(4000)"

    # components
    content::type::new -content_type imsld_component -supertype content_revision -pretty_name "#imsld.IMS-LD_Component#" -pretty_plural "#imsld.IMS-LD_Components#" -table_name imsld_components -id_column component_id

    content::type::attribute::new -content_type imsld_component -attribute_name imsld_id -datatype number -pretty_name "#imsld.IMS-LD_Identifier#" -column_spec "integer"
    
    # imsld roles
    content::type::new -content_type imsld_role -supertype content_revision -pretty_name "#imsld.IMS-LD_Role#" -pretty_plural "#imsld.IMS-LD_Roles#" -table_name imsld_roles -id_column role_id

    content::type::attribute::new -content_type imsld_role -attribute_name component_id -datatype string -pretty_name "#imsld.Component_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role -attribute_name identifier -datatype string -pretty_name "#imsld.Identifier#" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_role -attribute_name role_type -datatype string  -pretty_name "#imsld.Role_Type#" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_role -attribute_name parent_role_id -datatype number -pretty_name "#imsld.lt_Parent_Role_Identifie#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role -attribute_name create_new_p -datatype string -pretty_name "#imsld.Create_New#" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_role -attribute_name match_persons_p -datatype string -pretty_name "#imsld.Match_Persons#" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_role -attribute_name max_persons -datatype number -pretty_name "#imsld.Max_Persons#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role -attribute_name min_persons -datatype number -pretty_name "#imsld.Min_Persons#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role -attribute_name href -datatype string -pretty_name "#imsld.Href#" -column_spec "varchar(2000)"

    # imsld activity description
    content::type::new -content_type imsld_activity_desc -supertype content_revision -pretty_name "#imsld.lt_IMS-LD_Activity_Descr#" -pretty_plural "#imsld.lt_IMS-LD_Activity_Descr_1#" -table_name imsld_activity_descs -id_column description_id

    content::type::attribute::new -content_type imsld_activity_desc -attribute_name pretty_title -datatype string -pretty_name "#imsld.Pretty_Title#" -column_spec "varchar(200)"

    # learning activities
    content::type::new -content_type imsld_learning_activity -supertype content_revision -pretty_name "#imsld.lt_IMS-LD_Learning_Activ#" -pretty_plural "#imsld.lt_IMS-LD_Learning_Activ_1#" -table_name imsld_learning_activities -id_column activity_id
    
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name identifier -datatype string -pretty_name "#imsld.Identifier#" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name component_id -datatype number -pretty_name "#imsld.Component_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name activity_description_id -datatype number -pretty_name "#imsld.lt_Activity_Description_#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name is_visible_p -datatype string -pretty_name "#imsld.Is_Visible#" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name complete_act_id -datatype number -pretty_name "#imsld.lt_Complete_Act_Identifi#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name on_completion_id -datatype number -pretty_name "#imsld.lt_On_Completion_Identif#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name parameters -datatype string -pretty_name "#imsld.Parameters#" -column_spec "varchar(4000)"
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name learning_objective_id -datatype number -pretty_name "#imsld.lt_Learning_Objective_ID#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name prerequisite_id -datatype number -pretty_name "#imsld.Prerequistes_ID#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_learning_activity -attribute_name sort_order -datatype number -pretty_name "#imsld.Sort_Order#" -column_spec "integer"

    # support activities
    content::type::new -content_type imsld_support_activity -supertype content_revision -pretty_name "#imsld.lt_IMS-LD_Support_Activi#" -pretty_plural "#imsld.lt_IMS-LD_Support_Activi_1#" -table_name imsld_support_activities -id_column activity_id
    
    content::type::attribute::new -content_type imsld_support_activity -attribute_name identifier -datatype string -pretty_name "#imsld.Identifier#" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_support_activity -attribute_name component_id -datatype number -pretty_name "#imsld.Component_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_support_activity -attribute_name activity_description_id -datatype number -pretty_name "#imsld.lt_Activity_Description_#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_support_activity -attribute_name parameter_id -datatype number -pretty_name "#imsld.Parameter_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_support_activity -attribute_name is_visible_p -datatype string -pretty_name "#imsld.Is_Visible#" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_support_activity -attribute_name complete_act_id -datatype number -pretty_name "#imsld.lt_Complete_Act_Identifi#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_support_activity -attribute_name on_completion_id -datatype number -pretty_name "#imsld.lt_On_Completion_Identif#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_support_activity -attribute_name parameters -datatype string -pretty_name "#imsld.Parameters#" -column_spec "varchar(4000)"
    content::type::attribute::new -content_type imsld_support_activity -attribute_name sort_order -datatype number -pretty_name "#imsld.Sort_Order#" -column_spec "integer"

    # activity structures
    content::type::new -content_type imsld_activity_structure -supertype content_revision -pretty_name "#imsld.lt_IMS-LD_Activity_Struc#" -pretty_plural "#imsld.lt_IMS-LD_Activity_Struc_1#" -table_name imsld_activity_structures -id_column structure_id 

    content::type::attribute::new -content_type imsld_activity_structure -attribute_name component_id -datatype number -pretty_name "#imsld._Component#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_activity_structure -attribute_name identifier -datatype string -pretty_name "#imsld.Identifier#" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_activity_structure -attribute_name number_to_select -datatype number -pretty_name "#imsld.Number_to_Select#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_activity_structure -attribute_name structure_type -datatype string -pretty_name "#imsld.Structure_Type#" -column_spec "char(9)"
    content::type::attribute::new -content_type imsld_activity_structure -attribute_name sort -datatype string -pretty_name "#imsld.Sort#" -column_spec "varchar(4)"
    content::type::attribute::new -content_type imsld_activity_structure -attribute_name sort_order -datatype number -pretty_name "#imsld.Sort_Order#" -column_spec "integer"

    # environments
    content::type::new -content_type imsld_environment -supertype content_revision -pretty_name "#imsld.IMD-LD_Environment#" -pretty_plural "#imsld.IMD-LD_Environments#" -table_name imsld_environments -id_column environment_id
    
    content::type::attribute::new -content_type imsld_environment -attribute_name component_id -datatype number -pretty_name "#imsld.Component_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_environment -attribute_name identifier -datatype string -pretty_name "#imsld.Identifier#" -column_spec "varchar(100)"

    # services
    content::type::new -content_type imsld_service -supertype content_revision -pretty_name "#imsld.IMS-LD_Service#" -pretty_plural "#imsld.IMS-LD_Services#" -table_name imsld_services -id_column service_id
    
    content::type::attribute::new -content_type imsld_service -attribute_name environment_id -datatype number -pretty_name "#imsld.lt_Environment_Identifie#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_service -attribute_name identifier -datatype string -pretty_name "#imsld.Identifier#" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_service -attribute_name class -datatype string -pretty_name "#imsld.Class#" -column_spec "varchar(4000)"
    content::type::attribute::new -content_type imsld_service -attribute_name is_visible_p -datatype string -pretty_name "#imsld.Is_Visible#" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_service -attribute_name parameters -datatype string -pretty_name "#imsld.Parameters#" -column_spec "varchar(4000)"
    content::type::attribute::new -content_type imsld_service -attribute_name service_type -datatype string -pretty_name "#imsld.Service_Type#" -column_spec "varchar(10)"

    # send mail services
    content::type::new -content_type imsld_send_mail_service -supertype content_revision -pretty_name "#imsld.lt_IMS-LD_Sendmail_Servi#" -pretty_plural "#imsld.lt_IMS-LD_Sendmail_Servi_1#" -table_name imsld_send_mail_services -id_column mail_id
    
    content::type::attribute::new -content_type imsld_send_mail_service -attribute_name service_id -datatype number -pretty_name "#imsld.Service_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_send_mail_service -attribute_name recipients -datatype string -pretty_name "#imsld.Recipients#" -column_spec "varchar(11)"
    content::type::attribute::new -content_type imsld_send_mail_service -attribute_name is_visible_p -datatype string -pretty_name "#imsld.Is_Visible#" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_send_mail_service -attribute_name parameters -datatype string -pretty_name "#imsld.Parameters#" -column_spec "varchar(4000)"

    # send mail data
    content::type::new -content_type imsld_send_mail_data -supertype content_revision -pretty_name "#imsld.IMS-LD_Sendmail_Data#" -pretty_plural "#imsld.IMS-LD_Sendmail_Data#" -table_name imsld_send_mail_data -id_column data_id

    content::type::attribute::new -content_type imsld_send_mail_data -attribute_name role_id -datatype number -pretty_name "#imsld.Role_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_send_mail_data -attribute_name mail_data -datatype string -pretty_name "#imsld.Mail_Data#" -column_spec "varchar(4000)"

    # conference services
    content::type::new -content_type imsld_conference_service -supertype content_revision -pretty_name "#imsld.lt_IMS-LD_Conference_Ser#" -pretty_plural "#imsld.lt_IMS-LD_Conference_Ser_1#" -table_name imsld_conference_services -id_column conference_id

    content::type::attribute::new -content_type imsld_conference_service -attribute_name service_id -datatype number -pretty_name "#imsld.Service_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_conference_service -attribute_name conference_type -datatype string -pretty_name "#imsld.Conference_Type#" -column_spec "char(12)"
    content::type::attribute::new -content_type imsld_conference_service -attribute_name imsld_item_id -datatype number -pretty_name "#imsld.Item_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_conference_service -attribute_name manager_id -datatype number -pretty_name "#imsld.Manager_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_conference_service -attribute_name moderator_id -datatype number -pretty_name "#imsld.Moderator_Identifier#"  -column_spec "integer"
    
    # methods
    content::type::new -content_type imsld_method -supertype content_revision -pretty_name "#imsld.IMS-LD_Method#" -pretty_plural "#imsld.IMS-LD_Methods#" -table_name imsld_methods -id_column method_id
    
    content::type::attribute::new -content_type imsld_method -attribute_name imsld_id -datatype number -pretty_name "#imsld.IMS-LD_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_method -attribute_name complete_act_id -datatype number -pretty_name "#imsld.lt_Complete_Act_Identifi#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_method -attribute_name on_completion_id -datatype number -pretty_name "#imsld.lt_On_Completion_Identif#" -column_spec "integer"

    # plays
    content::type::new -content_type imsld_play -supertype content_revision -pretty_name "#imsld.IMS-LD_Play#" -pretty_plural "#imsld.IMS-LD_Plays#" -table_name imsld_plays -id_column play_id

    content::type::attribute::new -content_type imsld_play -attribute_name method_id -datatype number -pretty_name "#imsld.Method_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_play -attribute_name is_visible_p -datatype string -pretty_name "#imsld.Is_Visible#" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_play -attribute_name identifier -datatype string -pretty_name "#imsld.Identifier#" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_play -attribute_name complete_act_id -datatype number -pretty_name "#imsld.lt_Complete_Act_Identifi#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_play -attribute_name on_completion_id -datatype number -pretty_name "#imsld.lt_On_Completion_Identif#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_play -attribute_name sort_order -datatype number -pretty_name "#imsld.Sort_Order#" -column_spec "integer"
    
    # acts
    content::type::new -content_type imsld_act -supertype content_revision -pretty_name "#imsld.IMS-LD_Act#" -pretty_plural "#imsld.IMS-LD_Acts#" -table_name imsld_acts -id_column act_id

    content::type::attribute::new -content_type imsld_act -attribute_name play_id -datatype number -pretty_name "#imsld.Play_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_act -attribute_name complete_act_id -datatype number -pretty_name "#imsld.lt_Complete_Act_Identifi#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_act -attribute_name identifier -datatype string -pretty_name "#imsld.Identifier#" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_act -attribute_name on_completion_id -datatype number -pretty_name "#imsld.lt_On_Completion_Identif#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_act -attribute_name sort_order -datatype number -pretty_name "#imsld.Sort_Order#" -column_spec "integer"

    # role parts
    content::type::new -content_type imsld_role_part -supertype content_revision -pretty_name "#imsld.IMS-LD_Role_Part#" -pretty_plural "#imsld.IMS-LD_Role_Parts#" -table_name imsld_role_parts -id_column role_part_id

    content::type::attribute::new -content_type imsld_role_part -attribute_name act_id -datatype number -pretty_name "#imsld.Act_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role_part -attribute_name identifier -datatype string -pretty_name "#imsld.Identifier#" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_role_part -attribute_name role_id -datatype number -pretty_name "#imsld.Role_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role_part -attribute_name learning_activity_id -datatype number -pretty_name "#imsld.lt_Learning_Activity_Ide#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role_part -attribute_name support_activity_id -datatype number -pretty_name "#imsld.lt_Support_Activity_Iden#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role_part -attribute_name activity_structure_id -datatype number -pretty_name "#imsld.lt_Activity_Structure_Id#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role_part -attribute_name environment_id -datatype number -pretty_name "#imsld.lt_Environment_Identifie#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_role_part -attribute_name sort_order -datatype number -pretty_name "#imsld.Sort_Order#" -column_spec "integer"

    # complete acts
    content::type::new -content_type imsld_complete_act -supertype content_revision -pretty_name "#imsld.Complete_Act#" -pretty_plural "#imsld.Complete_Acts#" -table_name imsld_complete_acts -id_column complete_act_id
    
    content::type::attribute::new -content_type imsld_complete_act -attribute_name time_in_seconds -datatype number -pretty_name "#imsld.Time_in_Seconds#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_complete_act -attribute_name time_string -datatype string -pretty_name "#imsld.Time_String#" -column_spec "varchar(30)"
    content::type::attribute::new -content_type imsld_complete_act -attribute_name user_choice_p -datatype string -pretty_name "#imsld.User_Choice#" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_complete_act -attribute_name when_last_act_completed_p -datatype string -pretty_name "#imsld.lt_When_Last_Act_Complet#" -column_spec "char(1)"

    # on completion
    content::type::new -content_type imsld_on_completion -supertype content_revision -pretty_name "#imsld.IMS-LD_On_Completion#" -pretty_plural "#imsld.lt_IMS-LD_On_Completions#" -table_name imsld_on_completion -id_column on_completion_id

    content::type::attribute::new -content_type imsld_on_completion -attribute_name feedback_title -datatype string -pretty_name "#imsld.Feedbach_Title#" -column_spec "varchar(200)"

    # classes
    content::type::new -content_type imsld_class -supertype content_revision -pretty_name "#imsld.IMS-LD_Class#" -pretty_plural "#imsld.IMS-LD_Classes#" -table_name imsld_classes -id_column class_id

    content::type::attribute::new -content_type imsld_class -attribute_name method_id -datatype number -pretty_name "#imsld.Method_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_class -attribute_name identifier -datatype string -pretty_name "#imsld.lt_IMS-LD_Class_Ideintif#" -column_spec "varchar(200)"

    ### IMS-LD Content Packaging

    # manifests
    content::type::new -content_type imsld_cp_manifest -supertype content_revision -pretty_name "#imsld.IMS-LD_CP_Manifest#" -pretty_plural "#imsld.IMS-LD_CP_Manifests#" -table_name imsld_cp_manifests -id_column manifest_id

    content::type::attribute::new -content_type imsld_cp_manifest -attribute_name identifier -datatype string -pretty_name "#imsld.Identifier#" -column_spec "varchar(1000)"
    content::type::attribute::new -content_type imsld_cp_manifest -attribute_name version -datatype string -pretty_name "#imsld.Version#" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_cp_manifest -attribute_name parent_manifest_id -datatype number -pretty_name "#imsld.lt_Parent_Manifest_Ident#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_cp_manifest -attribute_name is_shared_p -datatype string -pretty_name "#imsld.Is_shared#" -column_spec "char(1)"

    # organizations
    content::type::new -content_type imsld_cp_organization -supertype content_revision -pretty_name "#imsld.lt_IMS-LD_CP_Organizatio#" -pretty_plural "#imsld.lt_IMS-LD_CP_Organizatio_1#" -table_name imsld_cp_organizations -id_column organization_id
    
    content::type::attribute::new -content_type imsld_cp_organization -attribute_name manifest_id -datatype number -pretty_name "#imsld.Manifest_Identifier#" -column_spec "integer"

    # resources
    content::type::new -content_type imsld_cp_resource -supertype content_revision -pretty_name "#imsld.IMS-LD_CP_Resource#" -pretty_plural "#imsld.IMS-LD_CP_Resources#" -table_name imsld_cp_resources -id_column resource_id

    content::type::attribute::new -content_type imsld_cp_resource -attribute_name manifest_id -datatype number -pretty_name "#imsld.Manifest_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_cp_resource -attribute_name identifier -datatype string -pretty_name "#imsld.Identifier#" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_cp_resource -attribute_name type -datatype string -pretty_name "#imsld.Type#" -column_spec "varchar(1000)"
    content::type::attribute::new -content_type imsld_cp_resource -attribute_name href -datatype string -pretty_name "#imsld.Href#" -column_spec "varchar(2000)"
    content::type::attribute::new -content_type imsld_cp_resource -attribute_name acs_object_id -datatype number -pretty_name "acs_object_id" -column_spec "integer"

    # dependencies
    content::type::new -content_type imsld_cp_dependency -supertype content_revision -pretty_name "#imsld.IMS-LD_CP_Dependency#" -pretty_plural "#imsld.lt_IMS-LD_CP_Dependencie#" -table_name imsld_cp_dependencies -id_column dependency_id

    content::type::attribute::new -content_type imsld_cp_dependency -attribute_name resource_id -datatype number -pretty_name "#imsld.Resource_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_cp_dependency -attribute_name identifierref -datatype string -pretty_name "#imsld.Identifierref#" -column_spec "varchar(100)"

    # imsld cp files
    content::type::new -content_type imsld_cp_file -supertype content_revision -pretty_name "#imsld.IMS-LD_CP_File#" -pretty_plural "#imsld.IMS-LD_CP_Filed#" -table_name imsld_cp_files -id_column imsld_file_id

    content::type::attribute::new -content_type imsld_cp_file -attribute_name path_to_file -datatype string -pretty_name "#imsld.Path_to_File#" -column_spec "varchar(2000)"
    content::type::attribute::new -content_type imsld_cp_file -attribute_name file_name -datatype string -pretty_name "#imsld.File_name#" -column_spec "varchar(2000)"
    content::type::attribute::new -content_type imsld_cp_file -attribute_name href -datatype string -pretty_name "#imsld.Href#" -column_spec "varchar(2000)"


    ### IMS-LD LEVEL B

    # properties
    content::type::new -content_type imsld_property -supertype content_revision -pretty_name "#imsld.IMS-LD_Property#" -pretty_plural "#imsld.IMS-LD_Properties#" -table_name imsld_properties -id_column property_id

    content::type::attribute::new -content_type imsld_property -attribute_name component_id -datatype number -pretty_name "#imsld.Component_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_property -attribute_name identifier -datatype string -pretty_name "#imsld.Identifier#" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_property -attribute_name type -datatype string -pretty_name "#imsld.Type#" -column_spec "varchar(20)"
    content::type::attribute::new -content_type imsld_property -attribute_name datatype -datatype string -pretty_name "#imsld.Data_Type#" -column_spec "varchar(20)"
    content::type::attribute::new -content_type imsld_property -attribute_name initial_value -datatype string -pretty_name "#imsld.Initial_Value#" -column_spec "varchar(4000)"
    content::type::attribute::new -content_type imsld_property -attribute_name role_id -datatype number -pretty_name "#imsld.Role_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_property -attribute_name existing_href -datatype string -pretty_name "#imsld.Existing_href#" -column_spec "varchar(2000)"
    content::type::attribute::new -content_type imsld_property -attribute_name uri -datatype string -pretty_name "#imsld.URI#" -column_spec "varchar(2000)"

    # property groups
    content::type::new -content_type imsld_property_group -supertype content_revision -pretty_name "#imsld.lt_IMS-LD_Property_Group#" -pretty_plural "#imsld.lt_IMS-LD_Property_Group_1#" -table_name imsld_property_groups -id_column property_group_id

    content::type::attribute::new -content_type imsld_property_group -attribute_name component_id -datatype number -pretty_name "#imsld.Component_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_property_group -attribute_name identifier -datatype string -pretty_name "#imsld.Identifier#" -column_spec "varchar(100)"

    # property instances
    content::type::new -content_type imsld_property_instance -supertype content_revision -pretty_name "#imsld.lt_IMS-LD_Property_Insta#" -pretty_plural "#imsld.lt_IMS-LD_Property_Insta_1#" -table_name imsld_property_instances -id_column instance_id

    content::type::attribute::new -content_type imsld_property_instance -attribute_name property_id -datatype number -pretty_name "#imsld.Property_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_property_instance -attribute_name identifier -datatype string -pretty_name "#imsld.lt_Property_String_Ident#" -column_spec "varchar(100)"
    content::type::attribute::new -content_type imsld_property_instance -attribute_name party_id -datatype number -pretty_name "#imsld.Party_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_property_instance -attribute_name run_id -datatype number -pretty_name "#imsld.Run_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_property_instance -attribute_name value -datatype string -pretty_name "#imsld.Property_Value#" -column_spec "varchar(4000)"

    # restrictions
    content::type::new -content_type imsld_restriction -supertype content_revision -pretty_name "#imsld.IMS-LD_Restriction#" -pretty_plural "#imsld.IMS-LD_Restrictions#" -table_name imsld_restrictions -id_column restriction_id

    content::type::attribute::new -content_type imsld_restriction -attribute_name property_id -datatype number -pretty_name "#imsld.Property_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_restriction -attribute_name restriction_type -datatype string -pretty_name "#imsld.Restriction_Type#" -column_spec "varchar(20)"
    content::type::attribute::new -content_type imsld_restriction -attribute_name value -datatype string -pretty_name "#imsld.Value#" -column_spec "varchar"

    # complete acts
    content::type::attribute::new -content_type imsld_complete_act -attribute_name time_property_id -datatype number -pretty_name "#imsld.lt_Time_Property_Identif#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_complete_act -attribute_name when_condition_true_id -datatype number -pretty_name "#imsld.When_Condition_True#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_complete_act -attribute_name when_prop_val_is_set_xml -datatype string -pretty_name "#imsld.lt_When_property_value_i#" -column_spec "varchar(4000)"

    # on completion
    content::type::attribute::new -content_type imsld_on_completion -attribute_name change_property_value_xml -datatype string -pretty_name "#imsld.lt_Change_Property_Value_1#" -column_spec "varchar(4000)"

    # monitor service
    content::type::new -content_type imsld_monitor_service -supertype content_revision -pretty_name "#imsld.lt_IMS-LD_Monitor_Servic#" -pretty_plural "#imsld.lt_IMS-LD_Monitor_Servic_1#" -table_name imsld_monitor_services -id_column monitor_id

    content::type::attribute::new -content_type imsld_monitor_service -attribute_name service_id -datatype number -pretty_name "#imsld.Service_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_monitor_service -attribute_name role_id -datatype number -pretty_name "#imsld.Role_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_monitor_service -attribute_name self_p -datatype string -pretty_name "#imsld.Self#" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_monitor_service -attribute_name imsld_item_id -datatype number -pretty_name "#imsld.lt_IMS-LD_Item_Identifie#" -column_spec "integer"

    # send mail data
    content::type::attribute::new -content_type imsld_send_mail_data -attribute_name email_property_id -datatype number -pretty_name "#imsld.lt_Email_Propery_Identif#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_send_mail_data -attribute_name username_property_id -datatype number -pretty_name "#imsld.lt_Username_Property_Ide#" -column_spec "integer"

    # when condition true
    content::type::new -content_type imsld_when_condition_true -supertype content_revision -pretty_name "#imsld.lt_IMS-LD_When_Condition#" -pretty_plural "#imsld.lt_IMS-LD_When_Condition_1#" -table_name imsld_when_condition_true -id_column when_condition_true_id

    content::type::attribute::new -content_type imsld_when_condition_true -attribute_name role_id -datatype number -pretty_name "#imsld.Role_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_when_condition_true -attribute_name expression_xml -datatype string -pretty_name "#imsld.Expression#" -column_spec "varchar(4000)"

    # conditions 
    content::type::new -content_type imsld_condition -supertype content_revision -pretty_name "#imsld.IMS-LD_Condition#" -pretty_plural "#imsld.IMS-LD_Conditions#" -table_name imsld_conditions -id_column condition_id

    content::type::attribute::new -content_type imsld_condition -attribute_name method_id -datatype number -pretty_name "#imsld.Method_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_condition -attribute_name condition_xml -datatype string -pretty_name "#imsld.Condition#" -column_spec "varchar(4000)"

    ### IMS-LD LEVEL C

    # notifications
    content::type::new -content_type imsld_notification -supertype content_revision -pretty_name "#imsld.Notification#" -pretty_plural "#imsld.Notifications#"  -table_name imsld_notifications -id_column notification_id
    
    content::type::attribute::new -content_type imsld_notification -attribute_name imsld_id -datatype number -pretty_name "#imsld.IMS-LD_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_notification -attribute_name activity_id -datatype number -pretty_name "#imsld.Activity_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_notification -attribute_name subject -datatype string -pretty_name "#imsld.Notification_Subject#" -column_spec "varchar(4000)"
}

ad_proc -public imsld::install::create_group_types {  
} { 
    create groups needed to manage imsld functionallity
} { 
    group_type::new -group_type imsld_role_group -supertype group  "Role defined by IMS-LD" "Roles defined by IMS-LD"

    # the table name for the new group is badly taken from the group_type, that's why we named it imsld_run_users_group
    group_type::new -group_type imsld_run_users_group -supertype group  "IMS-LD Run Group" "IMS-LD Run Groups"
    attribute::add -min_n_values 0 -max_n_values 0 imsld_run_users_group integer "run_id" "Run ids"
    # FIX ME (there is no way to add attributes to the rels without creating the whole plsql code)
    package_recreate_hierarchy imsld_run_users_group
}

ad_proc -public imsld::install::init_ext_rels {  
} { 
    create default rels between imsld items and acs objects
} { 
    # ims-ld roles - oacs groups
    rel_types::new imsld_role_group_rel "ims-ld role - imsld_role_group" "ims-ld roles - imsld_role_groups"  \
        content_item 0 {} \
        imsld_role_group 0 {}
    
    # ims-ld role instance - ims-ld run
    rel_types::new imsld_roleinstance_run_rel "imsld role instance - imsld run" "imsld role instances - ims_ld_run_groups"  \
        imsld_role_group 0 {} \
        imsld_run_users_group 0 {} 
    
    # ims-ld run - oacs users
    rel_types::new -table_name imsld_run_users_group_rels \
        -create_table_p 0 \
        imsld_run_users_group_rel \
        "ims_ld_run_group - acs_users" "ims_ld_run_group - acs_users"  \
        imsld_run_users_group 0 {} \
        party 0 {}
    attribute::add -min_n_values 0 -max_n_values 0 imsld_run_users_group_rel integer "active_role_id" "Active Roles IDs"
    # FIX ME (there is no way to add attributes to the rels without creating the whole plsql code)
    package_recreate_hierarchy imsld_run_users_group
}

ad_proc -public imsld::install::init_rels {  
} { 
    Create default rels between imsld items
} { 
    
    # Learning Objetcives - IMS-LD Items
    rel_types::new imsld_lo_item_rel "Learing Objective - Imsld Item rel" "Learing Objective - Imsld Item rels"  \
        content_item 0 {} \
        content_item 0 {}

    # Resource - Files
    rel_types::new -table_name imsld_res_files_rels \
        -create_table_p 0 \
        imsld_res_files_rel \
        "Resource - Files rel" "Resource - Files rels"  \
        content_item 0 {} \
        content_item 0 {}
    attribute::add -min_n_values 0 -max_n_values 0 imsld_res_files_rel boolean "displayable_p" "Displayable?"
    # FIX ME (there is no way to add attributes to the rels without creating the whole plsql code)
    package_recreate_hierarchy imsld_res_files_rel

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
    rel_types::new -table_name imsld_as_la_rels \
        -create_table_p 0 \
        imsld_as_la_rel \
        "Activity Structure - Learning Activities (learning-activity-ref) rel" "Activity Structure - Learning Activities (learning-activity-ref) rels" \
        content_item 0 {} \
        content_item 0 {}
    attribute::add -min_n_values 0 -max_n_values 0 imsld_as_la_rel integer "sort_order" "Sort orders"
    # FIX ME (there is no way to add attributes to the rels without creating the whole plsql code)
    package_recreate_hierarchy imsld_as_la_rel
    
    # Activity Structure - Support Activities (support-activity-ref)
    rel_types::new -table_name imsld_as_sa_rels \
        -create_table_p 0 \
        imsld_as_sa_rel  \
        "Activity Structure - Support Activities (support-activity-ref) rel" "Activity Structure - Support Activities (support-activity-ref) rels" \
        content_item 0 {} \
        content_item 0 {}
    attribute::add -min_n_values 0 -max_n_values 0 imsld_as_sa_rel integer "sort_order" "Sort orders"
    # FIX ME (there is no way to add attributes to the rels without creating the whole plsql code)
    package_recreate_hierarchy imsld_as_sa_rel
    
    # Activity Structure - Activity Structures (activity-structure-ref)
    rel_types::new -table_name imsld_as_as_rels \
        -create_table_p 0 \
        imsld_as_as_rel \
        "Activity Structure - Activity Structures (activity-structure-ref) rel" "Activity Structure - Activity Structures (activity-structure-ref) rels" \
        content_item 0 {} \
        content_item 0 {}
    attribute::add -min_n_values 0 -max_n_values 0 imsld_as_as_rel integer "sort_order" "Sort orders"
    # FIX ME (there is no way to add attributes to the rels without creating the whole plsql code)
    package_recreate_hierarchy imsld_as_as_rel

    # Act - Role Parts (when-role-part-completed)
    rel_types::new imsld_act_rp_completed_rel "Act - Role Parts (when-role-part-completed) rel" "Act - Role Parts (when-role-part-completed) rels" \
        content_item 0 {} \
        content_item 0 {}

    # Method - Plays (when-play-completed)
    rel_types::new imsld_mp_completed_rel "Method - Plays (when-play-completed) rel" "Method - Plays (when-play-completed) rels" \
        content_item 0 {} \
        content_item 0 {}

    # Property Group - Properties
    rel_types::new imsld_gprop_prop_rel "Property Group - Properties rel" "Property Group - Properties rels" \
        content_item 0 {} \
        content_item 0 {}

    # Property Group - Property Groups
    rel_types::new imsld_gprop_gprop_rel "Property Group - Property Groups rel" "Property Group - Property Groups rels" \
        content_item 0 {} \
        content_item 0 {}

    # Properties - Conditions
    rel_types::new imsld_prop_cond_rel "Property - Condition" "Properties - Conditions" \
        content_item 0 {} \
        content_item 0 {}

    # Properties - When-condition-true
    rel_types::new imsld_prop_whct_rel "Property - when-condition-true" "Properties - When-Condition-True" \
        content_item 0 {} \
        content_item 0 {}

    # Properties - When property value is set
    rel_types::new imsld_prop_wpv_is_rel "Property - when property value is set" "Property - when property value is set" \
        content_item 0 {} \
        content_item 0 {}

    # Roles  - conditions
    rel_types::new imsld_role_cond_rel "Role - Condition" "Roles - Conditions" \
        content_item 0 {} \
        content_item 0 {}

    # Imsld learning material  - conditions
    rel_types::new imsld_ilm_cond_rel "Imsld Learning Material - Condition" "Imsld Learning Materials - Conditions" \
        content_item 0 {} \
        content_item 0 {}

    # Imsld on completion  - notifications
    rel_types::new imsld_on_comp_notif_rel "On Completion - Notification" "On Completion - Notifications" \
        content_item 0 {} \
        content_item 0 {}

    # Imsld notification  - email datas
    rel_types::new imsld_notif_email_rel "Notification - Email Data" "Notification - Email Datas" \
        content_item 0 {} \
        content_item 0 {}

    # Imsld send mail service  - email datas
    rel_types::new imsld_send_mail_serv_data_rel "Send Mail Service - Email Data" "Send Mail Service - Email Datas" \
        content_item 0 {} \
        content_item 0 {}
}

ad_proc -public imsld::install::after_upgrade {
    -from_version_name:required
    -to_version_name:required
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            0.1d 1.0d {
                ### IMS-LD LEVEL C
                
                # notifications
                content::type::new -content_type imsld_notification -supertype content_revision -pretty_name "#imsld.Notification#" -pretty_plural "#imsld.Notifications#"  -table_name imsld_notifications -id_column notification_id
                
                content::type::attribute::new -content_type imsld_notification -attribute_name imsld_id -datatype number -pretty_name "#imsld.IMS-LD_Identifier#" -column_spec "integer"
                content::type::attribute::new -content_type imsld_notification -attribute_name activity_id -datatype number -pretty_name "#imsld.Activity_Identifier#" -column_spec "integer"
                content::type::attribute::new -content_type imsld_notification -attribute_name subject -datatype string -pretty_name "#imsld.Notification_Subject#" -column_spec "varchar(4000)"
                
                # Imsld on completion  - notifications
                rel_types::new imsld_on_comp_notif_rel "On Completion - Notification" "On Completion - Notifications" \
                    content_item 0 {} \
                    content_item 0 {}
                
                # Imsld notification  - email datas
                rel_types::new imsld_notif_email_rel "Notification - Email Data" "Notification - Email Datas" \
                    content_item 0 {} \
                    content_item 0 {}
                
                # special case: add the new attributes, new rel and migrate the existing data
                content::type::attribute::new -content_type imsld_send_mail_data -attribute_name email_property_id -datatype number -pretty_name "#imsld.lt_Email_Propery_Identif#" -column_spec "integer"
                content::type::attribute::new -content_type imsld_send_mail_data -attribute_name username_property_id -datatype number -pretty_name "#imsld.lt_Username_Property_Ide#" -column_spec "integer"

                # Imsld send mail service  - email datas
                rel_types::new imsld_send_mail_serv_data_rel "Send Mail Service - Email Data" "Send Mail Service - Email Datas" \
                    content_item 0 {} \
                    content_item 0 {}
                
                db_foreach send_mail_data {
                    select serv.username_property_id, 
                    serv.email_property_id, 
                    data.data_id,
                    data.item_id as data_item_id,
                    serv.item_id as serv_item_id
                    from imsld_send_mail_datai data, imsld_send_mail_servicesi serv 
                    where data.send_mail_id = serv.item_id
                    and content_revision__is_live(serv.mail_id) = 't'
                } {

                    db_dml update_table {
                        update imsld_send_mail_data
                        set email_property_id = :email_property_id,
                        username_property_id = :username_property_id
                        where data_id = :data_id
                    }

                    relation_add imsld_notif_email_rel $serv_item_id $data_item_id
                }
                
                
                # finally, delete the attributes
                content::type::attribute::delete -content_type imsld_send_mail_data \
                    -attribute_name send_mail_id \
                    -drop_column t
                content::type::attribute::delete -content_type imsld_send_mail_service \
                    -attribute_name email_property_id \
                    -drop_column t
                content::type::attribute::delete -content_type imsld_send_mail_service \
                    -attribute_name username_property_id \
                    -drop_column t
                
                
            }
            1.0d 1.1d {
		# property instances
		content::type::new -content_type imsld_property_instance -supertype content_revision -pretty_name "#imsld.lt_IMS-LD_Property_Insta#" -pretty_plural "#imsld.lt_IMS-LD_Property_Insta_1#" -table_name imsld_property_instances -id_column instance_id
		
		content::type::attribute::new -content_type imsld_property_instance -attribute_name property_id -datatype number -pretty_name "#imsld.Property_Identifier#" -column_spec "integer"
		content::type::attribute::new -content_type imsld_property_instance -attribute_name identifier -datatype string -pretty_name "#imsld.lt_Property_String_Ident#" -column_spec "varchar(100)"
		content::type::attribute::new -content_type imsld_property_instance -attribute_name party_id -datatype number -pretty_name "#imsld.Party_Identifier#" -column_spec "integer"
		content::type::attribute::new -content_type imsld_property_instance -attribute_name run_id -datatype number -pretty_name "#imsld.Run_Identifier#" -column_spec "integer"
		content::type::attribute::new -content_type imsld_property_instance -attribute_name value -datatype string -pretty_name "#imsld.Property_Value#" -column_spec "varchar(4000)"

		set i 0
		foreach run [db_list_of_lists runs {
		    select ir.run_id,
		    ir.imsld_id,
		    ic.item_id as component_item_id,
		    icm.manifest_id,
		    rug.group_id as run_group_id
		    from imsld_runs ir,
		    imsld_imsldsi ii,
		    imsld_componentsi ic,
		    imsld_cp_organizationsi ico,
		    imsld_cp_manifestsi icm,
		    imsld_run_users_group_ext rug
		    where ir.imsld_id = ii.imsld_id
		    and ii.item_id = ic.imsld_id
		    and ii.organization_id = ico.item_id
		    and ico.manifest_id = icm.item_id
		    and rug.run_id = ir.run_id
		}] {
		    set run_id [lindex $run 0]
		    set imsld_id [lindex $run 1]
		    set component_item_id [lindex $run 2]
		    set manifest_id [lindex $run 3]
		    set run_group_id [lindex $run 4]
		    incr i
		    
		    set community_id [imsld::community_id_from_manifest_id -manifest_id $manifest_id]
		    set run_folder_id [imsld::instance::create_run_folder -run_id $run_id -community_id $community_id]
		    set cr_folder_id [content::item::get_parent_folder -item_id $component_item_id]
		    #in case the content type is not registered
		    content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_property_instance
		    content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_property_instance
		    set global_folder_id [imsld::global_folder_id -community_id $community_id]

		    db_foreach property_in_component {
			select property_id,
			identifier,
			type,
			datatype,
			initial_value,
			role_id,
			existing_href,
			uri,
			component_id as component_item_id
			from imsld_properties
			where component_id = :component_item_id
		    } {
			incr i
			switch $type {
			    loc {
				# get instance info
				if { ![db_0or1row get_instance_info {
				    select instance_id as old_instance_id,
				    party_id,
				    value
				    from imsld_property_instances
				    where property_id = :property_id
				    and identifier = :identifier
				    and run_id = :run_id
				}] } {
				    continue
				}

				if { ![db_0or1row loc_already_instantiated_p {
				    select 1
				    from imsld_property_instancesi
				    where property_id = :property_id
				    and identifier = :identifier
				    and run_id = :run_id
				}] } {
				    set instance_id [imsld::item_revision_new -attributes [list [list run_id $run_id] \
											       [list value $value] \
											       [list identifier $identifier] \
											       [list property_id $property_id]] \
							 -content_type imsld_property_instance \
							 -title $identifier \
							 -parent_id [expr [string eq $datatype "file"] ? $run_folder_id : $cr_folder_id]]
				    
				    if { [string eq $datatype "file"] } {
					# initialize the file to an empty one so the fs doesn't generate an error when requesting the file
					imsld::fs::empty_file -revision_id [content::item::get_live_revision -item_id $instance_id] -string $value
				    }
				    # delete old instance
				    db_dml delte_old_instance {
					delete from imsld_property_instances where instance_id = :old_instance_id
				    }
				}
			    }
			    locpers {
				foreach party_id [db_list users_in_run {
				    select ar.object_id_two as party_id
				    from acs_rels ar
				    where ar.object_id_one = :run_group_id
				    and ar.rel_type = 'imsld_run_users_group_rel'
				}] { 
				    
				    # get instance info
				    if { ![db_0or1row get_instance_info {
					select instance_id as old_instance_id,
					party_id,
					value
					from imsld_property_instances
					where property_id = :property_id
					and identifier = :identifier
					and party_id = :party_id
					and run_id = :run_id
				    }] } {
					continue
				    }
				    
				    if { ![db_0or1row locrole_already_instantiated_p {
					select 1
					from imsld_property_instancesi
					where property_id = :property_id
					and identifier = :identifier
					and party_id = :party_id
					and run_id = :run_id
				    }] } {
					set instance_id [imsld::item_revision_new -attributes [list [list run_id $run_id] \
												   [list value $value] \
												   [list identifier $identifier] \
												   [list party_id $party_id] \
												   [list property_id $property_id]] \
							     -content_type imsld_property_instance \
							     -title $identifier \
							     -parent_id [expr [string eq $datatype "file"] ? $run_folder_id : $cr_folder_id]]
					if { [string eq $datatype "file"] } {
					    # initialize the file to an empty one so the fs doesn't generate an error when requesting the file
					    imsld::fs::empty_file -revision_id [content::item::get_live_revision -item_id $instance_id] -string $value
					}
					# delete old instance
					db_dml delte_old_instance {
					    delete from imsld_property_instances where instance_id = :old_instance_id
					}
				    }
				}
			    }
			    locrole {
				foreach party_id [db_list roles_instances_in_run {
				    select ar1.object_id_two as party_id
				    from acs_rels ar1, acs_rels ar2, acs_rels ar3,
				    public.imsld_run_users_group_ext run_group
				    where ar1.rel_type = 'imsld_role_group_rel'
				    and ar1.object_id_two = ar2.object_id_one
				    and ar2.rel_type = 'imsld_roleinstance_run_rel'
				    and ar2.object_id_two = ar3.object_id_one
				    and ar3.object_id_one = run_group.group_id
				    and run_group.run_id = :run_id
				}] { 
				    # get instance info
				    if { ![db_0or1row get_instance_info {
					select instance_id as old_instance_id,
					party_id,
					value
					from imsld_property_instances
					where property_id = :property_id
					and identifier = :identifier
					and party_id = :party_id
					and run_id = :run_id
				    }] } {
					continue
				    }
				    
				    if { ![db_0or1row locrole_already_instantiated_p {
					select 1
					from imsld_property_instancesi
					where property_id = :property_id
					and identifier = :identifier
					and party_id = :party_id
					and run_id = :run_id
				    }] } {
					
					set instance_id [imsld::item_revision_new -attributes [list [list run_id $run_id] \
												   [list value $value] \
												   [list identifier $identifier] \
												   [list party_id $party_id] \
												   [list property_id $property_id]] \
							     -content_type imsld_property_instance \
							     -title $identifier \
							     -parent_id [expr [string eq $datatype "file"] ? $run_folder_id : $cr_folder_id]]
					if { [string eq $datatype "file"] } {
					    # initialize the file to an empty one so the fs doesn't generate an error when requesting the file
					    imsld::fs::empty_file -revision_id [content::item::get_live_revision -item_id $instance_id] -string $value
					}
					
					# delete old instance
					db_dml delte_old_instance {
					    delete from imsld_property_instances where instance_id = :old_instance_id
					}
				    }
				}
			    }
			    globpers {
				foreach party_id [db_list user_in_run {
				    select ar.object_id_two as party_id
				    from acs_rels ar
				    where ar.object_id_one = :run_group_id
				    and ar.rel_type = 'imsld_run_users_group_rel'
				}] {
				    # get instance info
				    if { ![db_0or1row get_instance_info {
					select instance_id as old_instance_id,
					party_id,
					value
					from imsld_property_instances
					where identifier = :identifier
					and party_id = :party_id
				    }] } {
					continue
				    }
				    
				    if { ![db_0or1row globpers_already_instantiated_p {
				    select 1 
					from imsld_property_instancesi
					where identifier = :identifier
					and party_id = :party_id
				    }] } {
					# not instantiated... is it already defined (existing href)? or must we use the one of the global definition?
					if { ![string eq $existing_href ""] } {
					    # it is already defined
					    # NOTE: there must be a better way to deal with this, 
					    # but by the moment we treat the href as the property value
					    set initial_value $existing_href
					} 
					# TODO: the property must be somehow instantiated in the given URI also
					set instance_id [imsld::item_revision_new -attributes [list [list value $value] \
												   [list identifier $identifier] \
												   [list party_id $party_id] \
												   [list property_id $property_id]] \
							     -content_type imsld_property_instance \
							     -title $identifier \
							     -parent_id [expr [string eq $datatype "file"] ? $global_folder_id : $cr_folder_id]]
					if { [string eq $datatype "file"] } {
					    # initialize the file to an empty one so the fs doesn't generate an error when requesting the file
					    imsld::fs::empty_file -revision_id [content::item::get_live_revision -item_id $instance_id] -string $value
					}
					
					# delete old instance
					db_dml delte_old_instance {
					    delete from imsld_property_instances where instance_id = :old_instance_id
					}
				    }
				}
			    }
			    global {
				# get instance info
				if { ![db_0or1row get_instance_info {
				    select instance_id as old_instance_id,
				    party_id,
				    value
				    from imsld_property_instances
				    where identifier = :identifier
				}] } {
				    continue
				}

				if { ![db_0or1row global_already_instantiated_p {
				    select 1 
				    from imsld_property_instancesi
				    where identifier = :identifier
				}] } {
				    # not instantiated... is it already defined (existing href)? or must we use the one of the global definition?
				    if { ![string eq $existing_href ""] } {
					# it is already defined
					# NOTE: there must be a better way to deal with this, but by the moment we treat the href as the property value
					set initial_value $existing_href
				    } 
				    # TODO: the property must be somehow instantiated in the given URI also
				    set instance_id [imsld::item_revision_new -attributes [list [list value $value] \
											       [list identifier $identifier] \
											       [list property_id $property_id]] \
							 -content_type imsld_property_instance \
							 -parent_id [expr [string eq $datatype "file"] ? $global_folder_id : $cr_folder_id]]
				    if { [string eq $datatype "file"] } {
					# initialize the file to an empty one so the fs doesn't generate an error when requesting the file
					imsld::fs::empty_file -revision_id [content::item::get_live_revision -item_id $instance_id] -string $value
				    }
				    
				    # delete old instance
				    db_dml delte_old_instance {
					delete from imsld_property_instances where instance_id = :old_instance_id
				    }
				}
			    }
			}
		    }
		}
	    }
        }
}   


ad_proc -public imsld::uninstall::delete_rels {  
} { 
    Delete default rels between imsld items
} {
    imsld::rel_type_delete -rel_type imsld_lo_item_rel
    imsld::rel_type_delete -rel_type imsld_res_files_rel
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
    imsld::rel_type_delete -rel_type imsld_gprop_prop_rel
    imsld::rel_type_delete -rel_type imsld_gprop_gprop_rel
    imsld::rel_type_delete -rel_type imsld_prop_cond_rel
    imsld::rel_type_delete -rel_type imsld_prop_whct_rel
    imsld::rel_type_delete -rel_type imsld_prop_wpv_is_rel
    imsld::rel_type_delete -rel_type imsld_role_cond_rel
    imsld::rel_type_delete -rel_type imsld_ilm_cond_rel
    imsld::rel_type_delete -rel_type imsld_on_comp_notif_rel
    imsld::rel_type_delete -rel_type imsld_notif_email_rel
    imsld::rel_type_delete -rel_type imsld_send_mail_serv_data_rel
}

ad_proc -public imsld::uninstall::delete_ext_rels {  
} { 
    Delete default rels between imsld and non IMS-LD objects
} { 
    imsld::rel_type_delete -rel_type imsld_role_group_rel
    imsld::rel_type_delete -rel_type imsld_roleinstance_run_rel
#TODO: drop attributes
    imsld::rel_type_delete -rel_type imsld_run_users_group_rel
}


ad_proc -public imsld::uninstall::delete_group_types {  
} { 
    Delete default group types
} {

    imsld::group_type_delete -group_type imsld_role_group 
#TODO: drop attributes
    imsld::group_type_delete -group_type imsld_run_users_group
}

ad_proc -public imsld::uninstall::empty_content_repository {  
} { 
    Deletes content types and attributes
} { 

    ### Attributes

    ### IMS-LD Level C
    content::type::attribute::delete -content_type imsld_notification -attribute_name imsld_id
    content::type::attribute::delete -content_type imsld_notification -attribute_name activity_id
    content::type::attribute::delete -content_type imsld_notification -attribute_name subject

    ### IMS-LD level B

    # properties
    content::type::attribute::delete -content_type imsld_property -attribute_name component_id
    content::type::attribute::delete -content_type imsld_property -attribute_name identifier
    content::type::attribute::delete -content_type imsld_property -attribute_name type
    content::type::attribute::delete -content_type imsld_property -attribute_name datatype
    content::type::attribute::delete -content_type imsld_property -attribute_name initial_value
    content::type::attribute::delete -content_type imsld_property -attribute_name role_id
    content::type::attribute::delete -content_type imsld_property -attribute_name existing_href
    content::type::attribute::delete -content_type imsld_property -attribute_name uri

    #property groups
    content::type::attribute::delete -content_type imsld_property_group -attribute_name component_id
    content::type::attribute::delete -content_type imsld_property_group -attribute_name identifier

    #property instances
    content::type::attribute::delete -content_type imsld_property_instance -attribute_name property_id
    content::type::attribute::delete -content_type imsld_property_instance -attribute_name identifier
    content::type::attribute::delete -content_type imsld_property_instance -attribute_name party_id 
    content::type::attribute::delete -content_type imsld_property_instance -attribute_name run_id
    content::type::attribute::delete -content_type imsld_property_instance -attribute_name value

    # restrictions
    content::type::attribute::delete -content_type imsld_restriction -attribute_name property_id
    content::type::attribute::delete -content_type imsld_restriction -attribute_name restriction_type
    content::type::attribute::delete -content_type imsld_restriction -attribute_name value

    # complete acts
    content::type::attribute::delete -content_type imsld_complete_act -attribute_name time_property_id
    content::type::attribute::delete -content_type imsld_complete_act -attribute_name when_condition_true_id
    content::type::attribute::delete -content_type imsld_complete_act -attribute_name when_prop_val_is_set_xml

    # monitor service
    content::type::attribute::delete -content_type imsld_monitor_service -attribute_name service_id
    content::type::attribute::delete -content_type imsld_monitor_service -attribute_name role_id
    content::type::attribute::delete -content_type imsld_monitor_service -attribute_name self_p 
    content::type::attribute::delete -content_type imsld_monitor_service -attribute_name imsld_item_id

    # send mail data
    content::type::attribute::delete -content_type imsld_send_mail_data -attribute_name email_property_id
    content::type::attribute::delete -content_type imsld_send_mail_data -attribute_name username_property_id

    # when condition true
    content::type::attribute::delete -content_type imsld_when_condition_true -attribute_name role_id
    content::type::attribute::delete -content_type imsld_when_condition_true -attribute_name expression_xml

    # conditions 
    content::type::attribute::delete -content_type imsld_condition -attribute_name method_id
    content::type::attribute::delete -content_type imsld_condition -attribute_name condition_xml

    ### IMS-LD Production and Delivery

    ### IMS-LD level A

    # learning objects
    content::type::attribute::delete -content_type imsld_learning_object -attribute_name environment_id
    content::type::attribute::delete -content_type imsld_learning_object -attribute_name identifier
    content::type::attribute::delete -content_type imsld_learning_object -attribute_name class
    content::type::attribute::delete -content_type imsld_learning_object -attribute_name is_visible_p
    content::type::attribute::delete -content_type imsld_learning_object -attribute_name type
    content::type::attribute::delete -content_type imsld_learning_object -attribute_name parameters

    # imsld
    content::type::attribute::delete -content_type imsld_imsld -attribute_name organization_id
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
    content::type::attribute::delete -content_type imsld_learning_activity -attribute_name complete_act_id
    content::type::attribute::delete -content_type imsld_learning_activity -attribute_name on_completion_id
    content::type::attribute::delete -content_type imsld_learning_activity -attribute_name parameters
    content::type::attribute::delete -content_type imsld_learning_activity -attribute_name learning_objective_id
    content::type::attribute::delete -content_type imsld_learning_activity -attribute_name prerequisite_id
    content::type::attribute::delete -content_type imsld_learning_activity -attribute_name sort_order

    # support activities
    content::type::attribute::delete -content_type imsld_support_activity -attribute_name identifier
    content::type::attribute::delete -content_type imsld_support_activity -attribute_name component_id
    content::type::attribute::delete -content_type imsld_support_activity -attribute_name activity_description_id
    content::type::attribute::delete -content_type imsld_support_activity -attribute_name parameter_id
    content::type::attribute::delete -content_type imsld_support_activity -attribute_name is_visible_p
    content::type::attribute::delete -content_type imsld_support_activity -attribute_name complete_act_id
    content::type::attribute::delete -content_type imsld_support_activity -attribute_name on_completion_id
    content::type::attribute::delete -content_type imsld_support_activity -attribute_name parameters
    content::type::attribute::delete -content_type imsld_support_activity -attribute_name sort_order

    # activity structures
    content::type::attribute::delete -content_type imsld_activity_structure -attribute_name component_id
    content::type::attribute::delete -content_type imsld_activity_structure -attribute_name identifier
    content::type::attribute::delete -content_type imsld_activity_structure -attribute_name number_to_select
    content::type::attribute::delete -content_type imsld_activity_structure -attribute_name structure_type
    content::type::attribute::delete -content_type imsld_activity_structure -attribute_name sort
    content::type::attribute::delete -content_type imsld_activity_structure -attribute_name sort_order

    # environments
    content::type::attribute::delete -content_type imsld_environment -attribute_name component_id
    content::type::attribute::delete -content_type imsld_environment -attribute_name identifier

    # services
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
    content::type::attribute::delete -content_type imsld_send_mail_data -attribute_name role_id
    content::type::attribute::delete -content_type imsld_send_mail_data -attribute_name mail_data
    
    # conference service
    content::type::attribute::delete -content_type imsld_conference_service -attribute_name service_id
    content::type::attribute::delete -content_type imsld_conference_service -attribute_name conference_type
    content::type::attribute::delete -content_type imsld_conference_service -attribute_name imsld_item_id
    content::type::attribute::delete -content_type imsld_conference_service -attribute_name manager_id
    content::type::attribute::delete -content_type imsld_conference_service -attribute_name moderator_id   
    # methods
    content::type::attribute::delete -content_type imsld_method -attribute_name imsld_id
    content::type::attribute::delete -content_type imsld_method -attribute_name complete_act_id
    content::type::attribute::delete -content_type imsld_method -attribute_name on_completion_id

    # plays
    content::type::attribute::delete -content_type imsld_play -attribute_name method_id
    content::type::attribute::delete -content_type imsld_play -attribute_name is_visible_p
    content::type::attribute::delete -content_type imsld_play -attribute_name identifier
    content::type::attribute::delete -content_type imsld_play -attribute_name complete_act_id
    content::type::attribute::delete -content_type imsld_play -attribute_name on_completion_id
    content::type::attribute::delete -content_type imsld_play -attribute_name sort_order

    # acts
    content::type::attribute::delete -content_type imsld_act -attribute_name play_id
    content::type::attribute::delete -content_type imsld_act -attribute_name complete_act_id
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

    # complete acts
    content::type::attribute::delete -content_type imsld_complete_act -attribute_name time_in_seconds
    content::type::attribute::delete -content_type imsld_complete_act -attribute_name user_choice_p
    content::type::attribute::delete -content_type imsld_complete_act -attribute_name when_last_act_completed_p

    # on completion
    content::type::attribute::delete -content_type imsld_on_completion -attribute_name feedback_title
    content::type::attribute::delete -content_type imsld_on_completion -attribute_name change_property_value_xml

    # classes
    content::type::attribute::delete -content_type imsld_class -attribute_name method_id
    content::type::attribute::delete -content_type imsld_class -attribute_name identifier

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
    content::type::attribute::delete -content_type imsld_cp_resource -attribute_name acs_object_id

    # dependencies
    content::type::attribute::delete -content_type imsld_cp_dependency -attribute_name resource_id
    content::type::attribute::delete -content_type imsld_cp_dependency -attribute_name identifierref

    # imsld cp files
    content::type::attribute::delete -content_type imsld_cp_file -attribute_name path_to_file
    content::type::attribute::delete -content_type imsld_cp_file -attribute_name file_name
    content::type::attribute::delete -content_type imsld_cp_file -attribute_name href

    ### IMS-LD Production and Delivery

    ### Content Types
    ### IMS-LD Production and Delivery
    db_dml delete_table_ipi { drop table imsld_property_instances }
    db_dml delete_table_isu { drop table imsld_status_user }
    db_dml delete_table_iai { drop table imsld_attribute_instances }
    db_dml delete_table_ir { drop table imsld_runs cascade}
    ### IMS-LD Level C
    content::type::delete -content_type imsld_notification  

    ### IMS-LD Level B
    content::type::delete -content_type imsld_property_instance
    content::type::delete -content_type imsld_property_groups  
    content::type::delete -content_type imsld_property  
    content::type::delete -content_type imsld_restriction  
    content::type::delete -content_type imsld_monitor_service  
    content::type::delete -content_type imsld_condition  
    content::type::delete -content_type imsld_when_condition_true  

    ### IMS-LD Level A
    content::type::delete -content_type imsld_learning_object  
    content::type::delete -content_type imsld_imsld 
    content::type::delete -content_type imsld_learning_objective 
    content::type::delete -content_type imsld_prerequisite 
    content::type::delete -content_type imsld_item 
    content::type::delete -content_type imsld_component 
    content::type::delete -content_type imsld_role 
    content::type::delete -content_type imsld_activity_desc 
    content::type::delete -content_type imsld_learning_activity 
    content::type::delete -content_type imsld_support_activity 
    content::type::delete -content_type imsld_activity_structure 
    content::type::delete -content_type imsld_environment 
    content::type::delete -content_type imsld_service 
    content::type::delete -content_type imsld_send_mail_service 
    content::type::delete -content_type imsld_send_mail_data 
    content::type::delete -content_type imsld_conference_service 
    content::type::delete -content_type imsld_method 
    content::type::delete -content_type imsld_play 
    content::type::delete -content_type imsld_act 
    content::type::delete -content_type imsld_role_part 
    content::type::delete -content_type imsld_complete_act 
    content::type::delete -content_type imsld_on_completion 
    content::type::delete -content_type imsld_class 

    ### IMS-LD Content Packaging
    content::type::delete -content_type imsld_cp_manifest 
    content::type::delete -content_type imsld_cp_organization 
    content::type::delete -content_type imsld_cp_resource 
    content::type::delete -content_type imsld_cp_dependency 
    content::type::delete -content_type imsld_cp_file 

}

