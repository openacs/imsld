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

    content::type::attribute::new -content_type imsld_send_mail_data -attribute_name send_mail_id -datatype number -pretty_name "#imsld.Sendmail_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_send_mail_data -attribute_name role_id -datatype number -pretty_name "#imsld.Role_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_send_mail_data -attribute_name mail_data -datatype string -pretty_name "#imsld.Mail_Data#" -column_spec "varchar(4000)"

    # conference services
    content::type::new -content_type imsld_conference_service -supertype content_revision -pretty_name "#imsld.lt_IMS-LD_Conference_Ser#" -pretty_plural "#imsld.lt_IMS-LD_Conference_Ser_1#" -table_name imsld_conference_services -id_column conference_id

    content::type::attribute::new -content_type imsld_conference_service -attribute_name service_id -datatype number -pretty_name "#imsld.Service_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_conference_service -attribute_name conference_type -datatype string -pretty_name "#imsld.Conference_Type#" -column_spec "char(12)"
    content::type::attribute::new -content_type imsld_conference_service -attribute_name imsld_item_id -datatype number -pretty_name "#imsld.Item_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_conference_service -attribute_name manager_id -datatype number -pretty_name "#imsld.Manager_Identifier#" -column_spec "integer"

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
    content::type::attribute::new -content_type imsld_complete_act -attribute_name user_choice_p -datatype string -pretty_name "#imsld.User_Choice#" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_complete_act -attribute_name when_last_act_completed_p -datatype string -pretty_name "#imsld.lt_When_Last_Act_Complet#" -column_spec "char(1)"

    # on completion
    content::type::new -content_type imsld_on_completion -supertype content_revision -pretty_name "#imsld.IMS-LD_On_Completion#" -pretty_plural "#imsld.lt_IMS-LD_On_Completions#" -table_name imsld_on_completion -id_column on_completion_id

    content::type::attribute::new -content_type imsld_on_completion -attribute_name feedback_title -datatype string -pretty_name "#imsld.Feedbach_Title#" -column_spec "varchar(200)"

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

    # restrictions
    content::type::new -content_type imsld_restriction -supertype content_revision -pretty_name "#imsld.IMS-LD_Restriction#" -pretty_plural "#imsld.IMS-LD_Restrictions#" -table_name imsld_restrictions -id_column restriction_id

    content::type::attribute::new -content_type imsld_restriction -attribute_name property_id -datatype number -pretty_name "#imsld.Property_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_restriction -attribute_name restriction_type -datatype string -pretty_name "#imsld.Restriction_Type#" -column_spec "varchar(20)"
    content::type::attribute::new -content_type imsld_restriction -attribute_name value -datatype string -pretty_name "#imsld.Value#" -column_spec "varchar"

    # property values
    content::type::new -content_type imsld_property_value -supertype content_revision -pretty_name "#imsld.lt_IMS-LD_Property_Value#" -pretty_plural "#imsld.lt_IMS-LD_Property_Value_1#" -table_name imsld_properties_values -id_column property_value_id

    content::type::attribute::new -content_type imsld_property_value -attribute_name property_id -datatype number -pretty_name "#imsld.Property_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_property_value -attribute_name langstring -datatype string -pretty_name "#imsld.Langstring#" -column_spec "varchar(4000)"
    content::type::attribute::new -content_type imsld_property_value -attribute_name expression_xml -datatype number -pretty_name "#imsld.Calculateexpression#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_property_value -attribute_name property_value_ref -datatype number -pretty_name "#imsld.Property_Value_Ref#" -column_spec "integer"

    # complete acts
    content::type::attribute::new -content_type imsld_complete_act -attribute_name time_property_id -datatype number -pretty_name "#imsld.lt_Time_Property_Identif#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_complete_act -attribute_name when_prop_val_is_set_id -datatype number -pretty_name "#imsld.lt_When_Property_Value_i#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_complete_act -attribute_name when_condition_true_id -datatype number -pretty_name "#imsld.When_Condition_True#" -column_spec "integer"

    # monitor service
    content::type::new -content_type imsld_monitor_service -supertype content_revision -pretty_name "#imsld.lt_IMS-LD_Monitor_Servic#" -pretty_plural "#imsld.lt_IMS-LD_Monitor_Servic_1#" -table_name imsld_monitor_services -id_column monitor_id

    content::type::attribute::new -content_type imsld_monitor_service -attribute_name service_id -datatype number -pretty_name "#imsld.Service_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_monitor_service -attribute_name role_id -datatype number -pretty_name "#imsld.Role_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_monitor_service -attribute_name self_p -datatype string -pretty_name "#imsld.Self#" -column_spec "char(1)"
    content::type::attribute::new -content_type imsld_monitor_service -attribute_name imsld_item_id -datatype number -pretty_name "#imsld.lt_IMS-LD_Item_Identifie#" -column_spec "integer"

    # send mail service
    content::type::attribute::new -content_type imsld_send_mail_service -attribute_name email_property_id -datatype number -pretty_name "#imsld.lt_Email_Propery_Identif#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_send_mail_service -attribute_name username_property_id -datatype number -pretty_name "#imsld.lt_Username_Property_Ide#" -column_spec "integer"

    # when condition true
    content::type::new -content_type imsld_when_condition_true -supertype content_revision -pretty_name "#imsld.lt_IMS-LD_When_Condition#" -pretty_plural "#imsld.lt_IMS-LD_When_Condition_1#" -table_name imsld_when_condition_true -id_column when_condition_true_id

    content::type::attribute::new -content_type imsld_when_condition_true -attribute_name role_id -datatype number -pretty_name "#imsld.Role_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_when_condition_true -attribute_name expression_xml -datatype string -pretty_name "#imsld.Expression#" -column_spec "varchar(4000)"

    # conditions 
    content::type::new -content_type imsld_condition -supertype content_revision -pretty_name "#imsld.IMS-LD_Condition#" -pretty_plural "#imsld.IMS-LD_Conditions#" -table_name imsld_conditions -id_column condition_id

    content::type::attribute::new -content_type imsld_condition -attribute_name method_id -datatype number -pretty_name "#imsld.Method_Identifier#" -column_spec "integer"
    content::type::attribute::new -content_type imsld_condition -attribute_name condition_xml -datatype string -pretty_name "#imsld.Condition#" -column_spec "varchar(4000)"
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
     rel_types::new imsld_run_users_group_rel "ims_ld_run_group - acs_users" "ims_ld_run_group - acs_users"  \
        imsld_run_users_group 0 {} \
        party 0 {}
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

    # On Completion - Change Property Values
    rel_types::new imsld_on_comp_change_pv_rel "On Completion - Change Property Values rel" "On Completion - Change Property Values rels" \
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
    imsld::rel_type_delete -rel_type imsld_on_comp_change_pv_rel
}

ad_proc -public imsld::uninstall::delete_ext_rels {  
} { 
    Delete default rels between imsld and non IMS-LD objects
} { 
    imsld::rel_type_delete -rel_type imsld_role_group_rel
    imsld::rel_type_delete -rel_type imsld_res_files_rel
}

ad_proc -public imsld::uninstall::empty_content_repository {  
} { 
    Deletes content types and attributes
} { 

    ### Attributes
    
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

    # restrictions
    content::type::attribute::delete -content_type imsld_restriction -attribute_name property_id
    content::type::attribute::delete -content_type imsld_restriction -attribute_name restriction_type
    content::type::attribute::delete -content_type imsld_restriction -attribute_name value

    # property values
    content::type::attribute::delete -content_type imsld_property_value -attribute_name property_id
    content::type::attribute::delete -content_type imsld_property_value -attribute_name langstring
    content::type::attribute::delete -content_type imsld_property_value -attribute_name expression_xml
    content::type::attribute::delete -content_type imsld_property_value -attribute_name property_value_ref

    # complete acts
    content::type::attribute::delete -content_type imsld_complete_act -attribute_name time_property_id
    content::type::attribute::delete -content_type imsld_complete_act -attribute_name when_prop_val_is_set_id
    content::type::attribute::delete -content_type imsld_complete_act -attribute_name when_condition_true_id

    # monitor service
    content::type::attribute::delete -content_type imsld_monitor_service -attribute_name service_id
    content::type::attribute::delete -content_type imsld_monitor_service -attribute_name role_id
    content::type::attribute::delete -content_type imsld_monitor_service -attribute_name self_p 
    content::type::attribute::delete -content_type imsld_monitor_service -attribute_name imsld_item_id

    # send mail service
    content::type::attribute::delete -content_type imsld_send_mail_service -attribute_name email_property_id
    content::type::attribute::delete -content_type imsld_send_mail_service -attribute_name username_property_id

    # when condition true
    content::type::attribute::delete -content_type imsld_when_condition_true -attribute_name role_id
    content::type::attribute::delete -content_type imsld_when_condition_true -attribute_name expression_xml

    # conditions 
    content::type::attribute::delete -content_type imsld_condition -attribute_name method_id
    content::type::attribute::delete -content_type imsld_condition -attribute_name condition_xml

    ### IMS-LD Production and Delivery
    content::type::attribute::delete -content_type imsld_property_instance -attribute_name property_id
    content::type::attribute::delete -content_type imsld_property_instance -attribute_name party_id
    content::type::attribute::delete -content_type imsld_property_instance -attribute_name value

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
    content::type::attribute::delete -content_type imsld_cp_file -attribute_name resource_id
    content::type::attribute::delete -content_type imsld_cp_file -attribute_name path_to_file
    content::type::attribute::delete -content_type imsld_cp_file -attribute_name file_name
    content::type::attribute::delete -content_type imsld_cp_file -attribute_name href

    ### IMS-LD Production and Delivery

    # imsld runs attributes
    foreach attribute_list [package_object_attribute_list imsld_run] {
        set attribute_id [lindex $attribute_list 0]
        attribute::delete $attribute_id
    }
    
    ### Content Types

    ### IMS-LD Level B
    content::type::delete -content_type imsld_property -drop_table_p t 
    content::type::delete -content_type imsld_property_groups -drop_table_p t 
    content::type::delete -content_type imsld_restriction -drop_table_p t 
    content::type::delete -content_type imsld_property_value -drop_table_p t 
    content::type::delete -content_type imsld_monitor_service -drop_table_p t 
    content::type::delete -content_type imsld_condition -drop_table_p t 
    content::type::delete -content_type imsld_when_condition_true -drop_table_p t 

    ### IMS-LD Level A
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
    content::type::delete -content_type imsld_complete_act -drop_table_p t
    content::type::delete -content_type imsld_on_completion -drop_table_p t

    ### IMS-LD Content Packaging
    content::type::delete -content_type imsld_cp_manifest -drop_table_p t
    content::type::delete -content_type imsld_cp_organization -drop_table_p t
    content::type::delete -content_type imsld_cp_resource -drop_table_p t
    content::type::delete -content_type imsld_cp_dependency -drop_table_p t
    content::type::delete -content_type imsld_cp_file -drop_table_p t

    ### IMS-LD Production and Delivery

    content::type::delete -content_type imsld_property_instance -drop_table_p t

}

