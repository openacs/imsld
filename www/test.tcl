ad_page_contract {
}

set page_title index
set context {}

db_foreach objeto {
    select object_id, last_modified
    from acs_objects
    order by last_modified asc
} {}

set ultimo "$object_id, $last_modified"

if {2==2} {
    ############## BEGIN
    # THIS CALLS MUST BE DONE IN DOTLRN APLET ADD APPLET TO COMMUNITY
    set community_id 2146
    
    # create relationship: dotLRN Community - IMS LD Manifests
    
    ############## END
} else {
    ############## BEGIN
    # THIS CALLS MUST BE DONE IN DOTLRN APLET REMOVE APPLET TO COMMUNITY
    imsld::rel_type_delete -rel_type imsld_community_manifest_rel
    
    ############## END
}

# ad_proc beta {} {} {
#     global sms
#     set sms "JA! vemonos los pies : "

#     upvar lista lista
#     set compy $lista
#     lappend lista [list c d]
#     zeta
# }

# ad_proc zeta {} {} {
#     upvar lista lista
#     lappend lista [list e f]
#     teta
# }

# ad_proc teta {} {} {
#     upvar lista lista
#     global sms
#     append sms sipuesdostres

#     set variable $sms

#     set stypmy $lista
#     lappend lista [list z z j]
#     lappend lista $sms
# }

# set lista [list a b]
# beta


if { 1==2 } {

    set mensaje "crear"
#     # learning objects
#     content::type::new -content_type imsld_learning_object -supertype content_revision -pretty_name "[_ imsld.Learning_Object]" -pretty_plural "[_ imsld.Learning_Objects]" -table_name imsld_learning_objects -id_column learning_object_id
    
#     content::type::attribute::new -content_type imsld_learning_object -attribute_name identifier -datatype string -pretty_name "[_ imsld.Identifier]" -column_spec "varchar(100)"
#     content::type::attribute::new -content_type imsld_learning_object -attribute_name class -datatype string -pretty_name "[_ imsld.Class]" -column_spec "varchar(4000)"
#     content::type::attribute::new -content_type imsld_learning_object -attribute_name is_visible_p -datatype string -pretty_name "[_ imsld.Is_Visible]" -column_spec "char(1)"
#     content::type::attribute::new -content_type imsld_learning_object -attribute_name type -datatype string -pretty_name "[_ imsld.Type]" -column_spec "varchar(100)"
#     content::type::attribute::new -content_type imsld_learning_object -attribute_name parameters -datatype string -pretty_name "[_ imsld.Parameters]" -column_spec "varchar(4000)"
    
#     # imsld 
#     content::type::new -content_type imsld_imsld -supertype content_revision -pretty_name "[_ imsld.IMS-LD]" -pretty_plural "[_ imsld.IMS-LDs]" -table_name imsld_imslds -id_column imsld_id 

#     content::type::attribute::new -content_type imsld_imsld -attribute_name identifier -datatype string -pretty_name "[_ imsld.Identifier]" -column_spec "varchar(100)"
#     content::type::attribute::new -content_type imsld_imsld -attribute_name version -datatype string -pretty_name "[_ imsld.Version]" -column_spec "varchar(10)"
#     content::type::attribute::new -content_type imsld_imsld -attribute_name level -datatype string -pretty_name "[_ imsld.Level]" -column_spec "char(1)"
#     content::type::attribute::new -content_type imsld_imsld -attribute_name sequence_used_p -datatype string -pretty_name "[_ imsld.Sequence_Used]" -column_spec "char(1)"
#     content::type::attribute::new -content_type imsld_imsld -attribute_name learning_objective_id -datatype number -pretty_name "[_ imsld.lt_Learning_Objectives_I]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_imsld -attribute_name prerequisite_id -datatype number -pretty_name "[_ imsld.Prerequistes_ID]" -column_spec "integer"

#     # learning objectives
#     content::type::new -content_type imsld_learning_objective -supertype content_revision -pretty_name "[_ imsld.lt_IMS-LD_Learning_Objec]" -pretty_plural "[_ imsld.lt_IMS-LD_Learning_Objec_1]" -table_name imsld_learning_objectives -id_column learning_object_id

#     content::type::attribute::new -content_type imsld_learning_objective -attribute_name pretty_title -datatype string -pretty_name "[_ imsld.Pretty_Title]" -column_spec "varchar(200)"

#     # imsld prerequisites
#     content::type::new -content_type imsld_prerequisite -supertype content_revision -pretty_name "[_ imsld.IMS-LD_Prerequisite]" -pretty_plural "[_ imsld.IMS-LD_Prerequisites]" -table_name imsld_prerequisites -id_column prerequisite_id

#     content::type::attribute::new -content_type imsld_prerequisite -attribute_name pretty_title -datatype string -pretty_name "[_ imsld.Pretty_Title]" -column_spec "varchar(200)"

#     # imsld items
#     content::type::new -content_type imsld_item -supertype content_revision -pretty_name "[_ imsld.IMS-LD_Item]" -pretty_plural "[_ imsld.IMS-LD_Items]" -table_name imsld_items -id_column imsld_item_id

#     content::type::attribute::new -content_type imsld_item -attribute_name parent_item_id -datatype integer -pretty_name "[_ imsld.lt_Parent_Item_Identifie]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_item -attribute_name identifier -datatype string -pretty_name "[_ imsld.Identifier]" -column_spec "varchar(100)"
#     content::type::attribute::new -content_type imsld_item -attribute_name identifierref -datatype string -pretty_name "[_ imsld.Identifier_Reference]" -column_spec "varchar(100)"
#     content::type::attribute::new -content_type imsld_item -attribute_name is_visible_p -datatype string -pretty_name "[_ imsld.Is_Visible]" -column_spec "char(1)"
#     content::type::attribute::new -content_type imsld_item -attribute_name parameters -datatype string -pretty_name "[_ imsld.Parameters]" -column_spec "varchar(4000)"

#     # components
#     content::type::new -content_type imsld_component -supertype content_revision -pretty_name "[_ imsld.IMS-LD_Component]" -pretty_plural "[_ imsld.IMS-LD_Components]" -table_name imsld_components -id_column component_id

#     content::type::attribute::new -content_type imsld_component -attribute_name imsld_id -datatype number -pretty_name "[_ imsld.IMS-LD_Identifier]" -column_spec "integer"
    
#     # imsld roles
#     content::type::new -content_type imsld_role -supertype content_revision -pretty_name "[_ imsld.IMS-LD_Role]" -pretty_plural "[_ imsld.IMS-LD_Roles]" -table_name imsld_roles -id_column role_id

#     content::type::attribute::new -content_type imsld_role -attribute_name component_id -datatype string -pretty_name "[_ imsld.Component_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_role -attribute_name identifier -datatype string -pretty_name "[_ imsld.Identifier]" -column_spec "varchar(100)"
#     content::type::attribute::new -content_type imsld_role -attribute_name role_type -datatype string  -pretty_name "[_ imsld.Role_Type]" -column_spec "varchar(100)"
#     content::type::attribute::new -content_type imsld_role -attribute_name parent_role_id -datatype number -pretty_name "[_ imsld.lt_Parent_Role_Identifie]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_role -attribute_name create_new_p -datatype string -pretty_name "[_ imsld.Create_New]" -column_spec "char(1)"
#     content::type::attribute::new -content_type imsld_role -attribute_name match_persons_p -datatype string -pretty_name "[_ imsld.Match_Persons]" -column_spec "char(1)"
#     content::type::attribute::new -content_type imsld_role -attribute_name max_persons -datatype number -pretty_name "[_ imsld.Max_Persons]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_role -attribute_name min_persons -datatype number -pretty_name "[_ imsld.Min_Persons]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_role -attribute_name href -datatype string -pretty_name "[_ imsld.Href]" -column_spec "varchar(2000)"

#     # imsld activity description
#     content::type::new -content_type imsld_activity_desc -supertype content_revision -pretty_name "[_ imsld.lt_IMS-LD_Activity_Descr]" -pretty_plural "[_ imsld.lt_IMS-LD_Activity_Descr_1]" -table_name imsld_activity_desc -id_column description_id

#     content::type::attribute::new -content_type imsld_activity_desc -attribute_name pretty_title -datatype string -pretty_name "[_ imsld.Pretty_Title]" -column_spec "varchar(200)"

#     # learning activities
#     content::type::new -content_type imsld_learning_activity -supertype content_revision -pretty_name "[_ imsld.lt_IMS-LD_Learning_Activ]" -pretty_plural "[_ imsld.lt_IMS-LD_Learning_Activ_1]" -table_name imsld_learning_activities -id_column activity_id
    
#     content::type::attribute::new -content_type imsld_learning_activity -attribute_name identifier -datatype string -pretty_name "[_ imsld.Identifier]" -column_spec "varchar(100)"
#     content::type::attribute::new -content_type imsld_learning_activity -attribute_name component_id -datatype number -pretty_name "[_ imsld.Component_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_learning_activity -attribute_name activity_description_id -datatype number -pretty_name "[_ imsld.lt_Activity_Description_]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_learning_activity -attribute_name is_visible_p -datatype string -pretty_name "[_ imsld.Is_Visible]" -column_spec "char(1)"
#     content::type::attribute::new -content_type imsld_learning_activity -attribute_name user_choice_p -datatype string -pretty_name "[_ imsld.User_Choice]" -column_spec "char(1)"
#     content::type::attribute::new -content_type imsld_learning_activity -attribute_name time_limit_id -datatype number -pretty_name "[_ imsld.lt_Time_Limit_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_learning_activity -attribute_name on_completion_id -datatype number -pretty_name "[_ imsld.lt_On_Completion_Identif]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_learning_activity -attribute_name parameters -datatype string -pretty_name "[_ imsld.Parameters]" -column_spec "varchar(4000)"
#     content::type::attribute::new -content_type imsld_learning_activity -attribute_name learning_objective_id -datatype number -pretty_name "[_ imsld.lt_Learning_Objective_ID]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_learning_activity -attribute_name prerequisite_id -datatype number -pretty_name "[_ imsld.Prerequistes_ID]" -column_spec "integer"

#     # support activities
#     content::type::new -content_type imsld_support_activity -supertype content_revision -pretty_name "[_ imsld.lt_IMS-LD_Support_Activi]" -pretty_plural "[_ imsld.lt_IMS-LD_Support_Activi_1]" -table_name imsld_support_activities -id_column activity_id
    
#     content::type::attribute::new -content_type imsld_support_activity -attribute_name identifier -datatype string -pretty_name "[_ imsld.Identifier]" -column_spec "varchar(100)"
#     content::type::attribute::new -content_type imsld_support_activity -attribute_name component_id -datatype number -pretty_name "[_ imsld.Component_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_support_activity -attribute_name parameter_id -datatype number -pretty_name "[_ imsld.Parameter_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_support_activity -attribute_name is_visible_p -datatype string -pretty_name "[_ imsld.Is_Visible]" -column_spec "char(1)"
#     content::type::attribute::new -content_type imsld_support_activity -attribute_name user_choice_p -datatype string -pretty_name "[_ imsld.User_Choice]" -column_spec "char(1)"
#     content::type::attribute::new -content_type imsld_support_activity -attribute_name time_limit_id -datatype number -pretty_name "[_ imsld.lt_Time_Limit_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_support_activity -attribute_name on_completion_id -datatype number -pretty_name "[_ imsld.lt_On_Completion_Identif]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_support_activity -attribute_name parameters -datatype string -pretty_name "[_ imsld.Parameters]" -column_spec "varchar(4000)"

#     # activity structures
#     content::type::new -content_type imsld_activity_structure -supertype content_revision -pretty_name "[_ imsld.lt_IMS-LD_Activity_Struc]" -pretty_plural "[_ imsld.lt_IMS-LD_Activity_Struc_1]" -table_name imsld_activity_structures -id_column structure_id 

#     content::type::attribute::new -content_type imsld_activity_structure -attribute_name component_id -datatype number -pretty_name "[_ imsld._Component]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_activity_structure -attribute_name identifier -datatype string -pretty_name "[_ imsld.Identifier]" -column_spec "varchar(100)"
#     content::type::attribute::new -content_type imsld_activity_structure -attribute_name number_to_select -datatype number -pretty_name "[_ imsld.Number_to_Select]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_activity_structure -attribute_name structure_type -datatype string -pretty_name "[_ imsld.Structure_Type]" -column_spec "char(9)"
#     content::type::attribute::new -content_type imsld_activity_structure -attribute_name sort -datatype string -pretty_name "[_ imsld.Sort]" -column_spec "varchar(4)"

#     # environments
#     content::type::new -content_type imsld_environment -supertype content_revision -pretty_name "[_ imsld.IMD-LD_Environment]" -pretty_plural "[_ imsld.IMD-LD_Environments]" -table_name imsld_environments -id_column environment_id
    
#     content::type::attribute::new -content_type imsld_environment -attribute_name component_id -datatype number -pretty_name "[_ imsld.Component_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_environment -attribute_name identifier -datatype string -pretty_name "[_ imsld.Identifier]" -column_spec "varchar(100)"
#     content::type::attribute::new -content_type imsld_environment -attribute_name learning_object_id -datatype number -pretty_name "[_ imsld.lt_Learning_Object_Ident]" -column_spec "integer"

#     # services
#     content::type::new -content_type imsld_service -supertype content_revision -pretty_name "[_ imsld.IMS-LD_Service]" -pretty_plural "[_ imsld.IMS-LD_Services]" -table_name imsld_services -id_column service_id
    
#     content::type::attribute::new -content_type imsld_service -attribute_name environment_id -datatype number -pretty_name "[_ imsld.lt_Environment_Identifie]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_service -attribute_name identifier -datatype string -pretty_name "[_ imsld.Identifier]" -column_spec "varchar(100)"
#     content::type::attribute::new -content_type imsld_service -attribute_name class -datatype string -pretty_name "[_ imsld.Class]" -column_spec "varchar(4000)"
#     content::type::attribute::new -content_type imsld_service -attribute_name is_visible_p -datatype string -pretty_name "[_ imsld.Is_Visible]" -column_spec "char(1)"
#     content::type::attribute::new -content_type imsld_service -attribute_name parameters -datatype string -pretty_name "[_ imsld.Parameters]" -column_spec "varchar(4000)"
#     content::type::attribute::new -content_type imsld_service -attribute_name service_type -datatype string -pretty_name "[_ imsld.Service_Type]" -column_spec "varchar(10)"

#     # send mail services
#     content::type::new -content_type imsld_send_mail_service -supertype content_revision -pretty_name "[_ imsld.lt_IMS-LD_Sendmail_Servi]" -pretty_plural "[_ imsld.lt_IMS-LD_Sendmail_Servi_1]" -table_name imsld_send_mail_services -id_column mail_id
    
#     content::type::attribute::new -content_type imsld_send_mail_service -attribute_name service_id -datatype number -pretty_name "[_ imsld.Service_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_send_mail_service -attribute_name recipients -datatype string -pretty_name "[_ imsld.Recipients]" -column_spec "varchar(11)"
#     content::type::attribute::new -content_type imsld_send_mail_service -attribute_name is_visible_p -datatype string -pretty_name "[_ imsld.Is_Visible]" -column_spec "char(1)"
#     content::type::attribute::new -content_type imsld_send_mail_service -attribute_name parameters -datatype string -pretty_name "[_ imsld.Parameters]" -column_spec "varchar(4000)"

#     # send mail data
#     content::type::new -content_type imsld_send_mail_data -supertype content_revision -pretty_name "[_ imsld.IMS-LD_Sendmail_Data]" -pretty_plural "[_ imsld.IMS-LD_Sendmail_Data]" -table_name imsld_send_mail_data -id_column data_id

#     content::type::attribute::new -content_type imsld_send_mail_data -attribute_name send_mail_id -datatype number -pretty_name "[_ imsld.Sendmail_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_send_mail_data -attribute_name role_id -datatype number -pretty_name "[_ imsld.Role_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_send_mail_data -attribute_name mail_data -datatype string -pretty_name "[_ imsld.Mail_Data]" -column_spec "varchar(4000)"

#     # conference services
#     content::type::new -content_type imsld_conference_service -supertype content_revision -pretty_name "[_ imsld.lt_IMS-LD_Conference_Ser]" -pretty_plural "[_ imsld.lt_IMS-LD_Conference_Ser_1]" -table_name imsld_conference_services -id_column conference_id

#     content::type::attribute::new -content_type imsld_conference_service -attribute_name service_id -datatype number -pretty_name "[_ imsld.Service_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_conference_service -attribute_name conference_type -datatype string -pretty_name "[_ imsld.Conference_Type]" -column_spec "char(12)"
#     content::type::attribute::new -content_type imsld_conference_service -attribute_name imsld_item_id -datatype number -pretty_name "[_ imsld.Item_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_conference_service -attribute_name manager_id -datatype number -pretty_name "[_ imsld.Manager_Identifier]" -column_spec "integer"

#     # methods
#     content::type::new -content_type imsld_method -supertype content_revision -pretty_name "[_ imsld.IMS-LD_Method]" -pretty_plural "[_ imsld.IMS-LD_Methods]" -table_name imsld_methods -id_column method_id
    
#     content::type::attribute::new -content_type imsld_method -attribute_name imsld_id -datatype number -pretty_name "[_ imsld.IMS-LD_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_method -attribute_name time_limit_id -datatype number -pretty_name "[_ imsld.lt_Time_Limit_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_method -attribute_name on_completion_id -datatype number -pretty_name "[_ imsld.lt_On_Completion_Identif]" -column_spec "integer"

#     # plays
#     content::type::new -content_type imsld_play -supertype content_revision -pretty_name "[_ imsld.IMS-LD_Play]" -pretty_plural "[_ imsld.IMS-LD_Plays]" -table_name imsld_plays -id_column play_id

#     content::type::attribute::new -content_type imsld_play -attribute_name method_id -datatype number -pretty_name "[_ imsld.Method_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_play -attribute_name is_visible_p -datatype string -pretty_name "[_ imsld.Is_Visible]" -column_spec "char(1)"
#     content::type::attribute::new -content_type imsld_play -attribute_name identifier -datatype string -pretty_name "[_ imsld.Identifier]" -column_spec "varchar(100)"
#     content::type::attribute::new -content_type imsld_play -attribute_name when_last_act_completed_p -datatype string -pretty_name "[_ imsld.lt_When_Last_Act_Complet]" -column_spec "char(1)"
#     content::type::attribute::new -content_type imsld_play -attribute_name time_limit_id -datatype number -pretty_name "[_ imsld.lt_Time_Limit_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_play -attribute_name on_completion_id -datatype number -pretty_name "[_ imsld.lt_On_Completion_Identif]" -column_spec "integer"
    
#     # acts
#     content::type::new -content_type imsld_act -supertype content_revision -pretty_name "[_ imsld.IMS-LD_Act]" -pretty_plural "[_ imsld.IMS-LD_Acts]" -table_name imsld_acts -id_column act_id

#     content::type::attribute::new -content_type imsld_act -attribute_name play_id -datatype number -pretty_name "[_ imsld.Play_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_act -attribute_name time_limit_id -datatype number -pretty_name "[_ imsld.lt_Time_Limit_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_act -attribute_name identifier -datatype string -pretty_name "[_ imsld.Identifier]" -column_spec "varchar(100)"
#     content::type::attribute::new -content_type imsld_act -attribute_name on_completion_id -datatype number -pretty_name "[_ imsld.lt_On_Completion_Identif]" -column_spec "integer"

#     # role parts
#     content::type::new -content_type imsld_role_part -supertype content_revision -pretty_name "[_ imsld.IMS-LD_Role_Part]" -pretty_plural "[_ imsld.IMS-LD_Role_Parts]" -table_name imsld_role_parts -id_column role_part_id

#     content::type::attribute::new -content_type imsld_role_part -attribute_name identifier -datatype string -pretty_name "[_ imsld.Identifier]" -column_spec "varchar(100)"
#     content::type::attribute::new -content_type imsld_role_part -attribute_name role_id -datatype number -pretty_name "[_ imsld.Role_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_role_part -attribute_name learning_activity_id -datatype number -pretty_name "[_ imsld.lt_Learning_Activity_Ide]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_role_part -attribute_name support_activity_id -datatype number -pretty_name "[_ imsld.lt_Support_Activity_Iden]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_role_part -attribute_name activity_structure_id -datatype number -pretty_name "[_ imsld.lt_Activity_Structure_Id]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_role_part -attribute_name environment_id -datatype number -pretty_name "[_ imsld.lt_Environment_Identifie]" -column_spec "integer"

#     # parameters
#     content::type::new -content_type imsld_parameter -supertype content_revision -pretty_name "[_ imsld.IMS-LD_Parameter]" -pretty_plural "[_ imsld.IMS-LD_Parameters]" -table_name imsld_parameters -id_column parameter_id
    
#     content::type::attribute::new -content_type imsld_parameter -attribute_name value -datatype string -pretty_name "[_ imsld.Value]" -column_spec "varchar(4000)"

#     # time limits
#     content::type::new -content_type imsld_time_limit -supertype content_revision -pretty_name "[_ imsld.IMS-LD_Time_Limit]" -pretty_plural "[_ imsld.IMS-LD_Time_Limits]" -table_name imsld_time_limits -id_column time_limit_id
    
#     content::type::attribute::new -content_type imsld_time_limit -attribute_name time_in_seconds -datatype number -pretty_name "[_ imsld.Time_in_Seconds]" -column_spec "integer"

#     # on completion
#     content::type::new -content_type imsld_on_completion -supertype content_revision -pretty_name "[_ imsld.IMS-LD_On_Completion]" -pretty_plural "[_ imsld.lt_IMS-LD_On_Completions]" -table_name imsld_on_completion -id_column on_completion_id

#     content::type::attribute::new -content_type imsld_on_completion -attribute_name feedback_title -datatype string -pretty_name "[_ imsld.Feedbach_Title]" -column_spec "varchar(200)"

#     ### IMS-LD Content Packaging

#     # manifests
#     content::type::new -content_type imsld_cp_manifest -supertype content_revision -pretty_name "[_ imsld.IMS-LD_CP_Manifest]" -pretty_plural "[_ imsld.IMS-LD_CP_Manifests]" -table_name imsld_cp_manifests -id_column manifest_id

#     content::type::attribute::new -content_type imsld_cp_manifest -attribute_name identifier -datatype string -pretty_name "[_ imsld.Identifier]" -column_spec "varchar(1000)"
#     content::type::attribute::new -content_type imsld_cp_manifest -attribute_name version -datatype string -pretty_name "[_ imsld.Version]" -column_spec "varchar(100)"
#     content::type::attribute::new -content_type imsld_cp_manifest -attribute_name parent_manifest_id -datatype number -pretty_name "[_ imsld.lt_Parent_Manifest_Ident]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_cp_manifest -attribute_name is_shared_p -datatype string -pretty_name "[_ imsld.Is_shared]" -column_spec "char(1)"

#     # organizations
#     content::type::new -content_type imsld_cp_organization -supertype content_revision -pretty_name "[_ imsld.lt_IMS-LD_CP_Organizatio]" -pretty_plural "[_ imsld.lt_IMS-LD_CP_Organizatio_1]" -table_name imsld_cp_organizations -id_column organization_id
    
#     content::type::attribute::new -content_type imsld_cp_organization -attribute_name manifest_id -datatype number -pretty_name "[_ imsld.Manifest_Identifier]" -column_spec "integer"

#     # resources
#     content::type::new -content_type imsld_cp_resource -supertype content_revision -pretty_name "[_ imsld.IMS-LD_CP_Resource]" -pretty_plural "[_ imsld.IMS-LD_CP_Resources]" -table_name imsld_cp_resources -id_column resource_id

#     content::type::attribute::new -content_type imsld_cp_resource -attribute_name manifest_id -datatype number -pretty_name "[_ imsld.Manifest_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_cp_resource -attribute_name identifier -datatype string -pretty_name "[_ imsld.Identifier]" -column_spec "varchar(100)"
#     content::type::attribute::new -content_type imsld_cp_resource -attribute_name type -datatype string -pretty_name "[_ imsld.Type]" -column_spec "varchar(1000)"
#     content::type::attribute::new -content_type imsld_cp_resource -attribute_name href -datatype string -pretty_name "[_ imsld.Href]" -column_spec "varchar(2000)"

#     # dependencies
#     content::type::new -content_type imsld_cp_dependency -supertype content_revision -pretty_name "[_ imsld.IMS-LD_CP_Dependency]" -pretty_plural "[_ imsld.lt_IMS-LD_CP_Dependencie]" -table_name imsld_cp_dependencies -id_column dependency_id

#     content::type::attribute::new -content_type imsld_cp_dependency -attribute_name resource_id -datatype number -pretty_name "[_ imsld.Resource_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_cp_dependency -attribute_name identifierref -datatype string -pretty_name "[_ imsld.Identifierref]" -column_spec "varchar(100)"

#     # imsld cp files
#     content::type::new -content_type imsld_cp_file -supertype content_revision -pretty_name "[_ imsld.IMS-LD_CP_File]" -pretty_plural "[_ imsld.IMS-LD_CP_Filed]" -table_name imsld_cp_files -id_column imsld_file_id

#     content::type::attribute::new -content_type imsld_cp_file -attribute_name resource_id -datatype number -pretty_name "[_ imsld.Resource_Identifier]" -column_spec "integer"
#     content::type::attribute::new -content_type imsld_cp_file -attribute_name path_to_file -datatype string -pretty_name "[_ imsld.Path_to_File]" -column_spec "varchar(2000)"
#     content::type::attribute::new -content_type imsld_cp_file -attribute_name file_name -datatype string -pretty_name "[_ imsld.File_name]" -column_spec "varchar(2000)"
#     content::type::attribute::new -content_type imsld_cp_file -attribute_name href -datatype string -pretty_name "[_ imsld.Href]" -column_spec "varchar(2000)"


} else {
    set mensaje "borrar"

# imsld::apm_callback::before_uninstall
    # learning objects
#     content::type::attribute::delete -content_type imsld_learning_object -attribute_name identifier
#     content::type::attribute::delete -content_type imsld_learning_object -attribute_name class
#     content::type::attribute::delete -content_type imsld_learning_object -attribute_name is_visible_p
#     content::type::attribute::delete -content_type imsld_learning_object -attribute_name type
#     content::type::attribute::delete -content_type imsld_learning_object -attribute_name parameters

#     # imsld
#     content::type::attribute::delete -content_type imsld_imsld -attribute_name identifier
#     content::type::attribute::delete -content_type imsld_imsld -attribute_name version
#     content::type::attribute::delete -content_type imsld_imsld -attribute_name level
#     content::type::attribute::delete -content_type imsld_imsld -attribute_name sequence_used_p
#     content::type::attribute::delete -content_type imsld_imsld -attribute_name learning_objective_id
#     content::type::attribute::delete -content_type imsld_imsld -attribute_name prerequisite_id

#     # learning objectives
#     content::type::attribute::delete -content_type imsld_learning_objective -attribute_name pretty_title

#     # imsld prerequisites
#     content::type::attribute::delete -content_type imsld_prerequisite -attribute_name pretty_title

#     # imsld items
#     content::type::attribute::delete -content_type imsld_item -attribute_name parent_item_id
#     content::type::attribute::delete -content_type imsld_item -attribute_name identifier
#     content::type::attribute::delete -content_type imsld_item -attribute_name identifierref
#     content::type::attribute::delete -content_type imsld_item -attribute_name is_visible_p
#     content::type::attribute::delete -content_type imsld_item -attribute_name parameters

#     # componets
#     content::type::attribute::delete -content_type imsld_component -attribute_name imsld_id

#     # imsld roles
#     content::type::attribute::delete -content_type imsld_role -attribute_name component_id
#     content::type::attribute::delete -content_type imsld_role -attribute_name identifier
#     content::type::attribute::delete -content_type imsld_role -attribute_name role_type
#     content::type::attribute::delete -content_type imsld_role -attribute_name parent_role_id
#     content::type::attribute::delete -content_type imsld_role -attribute_name create_new_p
#     content::type::attribute::delete -content_type imsld_role -attribute_name match_persons_p
#     content::type::attribute::delete -content_type imsld_role -attribute_name max_persons
#     content::type::attribute::delete -content_type imsld_role -attribute_name min_persons
#     content::type::attribute::delete -content_type imsld_role -attribute_name href

#     # activity descriptions
#     content::type::attribute::delete -content_type imsld_activity_desc -attribute_name pretty_title

#     # learning activities
#     content::type::attribute::delete -content_type imsld_learning_activity -attribute_name identifier
#     content::type::attribute::delete -content_type imsld_learning_activity -attribute_name component_id
#     content::type::attribute::delete -content_type imsld_learning_activity -attribute_name activity_description_id
#     content::type::attribute::delete -content_type imsld_learning_activity -attribute_name is_visible_p
#     content::type::attribute::delete -content_type imsld_learning_activity -attribute_name user_choice_p
#     content::type::attribute::delete -content_type imsld_learning_activity -attribute_name time_limit_id
#     content::type::attribute::delete -content_type imsld_learning_activity -attribute_name on_completion_id
#     content::type::attribute::delete -content_type imsld_learning_activity -attribute_name parameters
#     content::type::attribute::delete -content_type imsld_learning_activity -attribute_name learning_objective_id
#     content::type::attribute::delete -content_type imsld_learning_activity -attribute_name prerequisite_id

#     # support activities
#     content::type::attribute::delete -content_type imsld_support_activity -attribute_name identifier
#     content::type::attribute::delete -content_type imsld_support_activity -attribute_name component_id
#     content::type::attribute::delete -content_type imsld_support_activity -attribute_name parameter_id
#     content::type::attribute::delete -content_type imsld_support_activity -attribute_name is_visible_p
#     content::type::attribute::delete -content_type imsld_support_activity -attribute_name user_choice_p
#     content::type::attribute::delete -content_type imsld_support_activity -attribute_name time_limit_id
#     content::type::attribute::delete -content_type imsld_support_activity -attribute_name on_completion_id
#     content::type::attribute::delete -content_type imsld_support_activity -attribute_name parameters

#     # activity structures
#     content::type::attribute::delete -content_type imsld_activity_structure -attribute_name component_id
#     content::type::attribute::delete -content_type imsld_activity_structure -attribute_name identifier
#     content::type::attribute::delete -content_type imsld_activity_structure -attribute_name number_to_select
#     content::type::attribute::delete -content_type imsld_activity_structure -attribute_name structure_type
#     content::type::attribute::delete -content_type imsld_activity_structure -attribute_name sort

#     # environments
#     content::type::attribute::delete -content_type imsld_environment -attribute_name component_id
#     content::type::attribute::delete -content_type imsld_environment -attribute_name identifier
#     content::type::attribute::delete -content_type imsld_environment -attribute_name learning_object_id

#     # send mail service
#     content::type::attribute::delete -content_type imsld_service -attribute_name environment_id
#     content::type::attribute::delete -content_type imsld_service -attribute_name identifier
#     content::type::attribute::delete -content_type imsld_service -attribute_name class
#     content::type::attribute::delete -content_type imsld_service -attribute_name is_visible_p
#     content::type::attribute::delete -content_type imsld_service -attribute_name parameters
#     content::type::attribute::delete -content_type imsld_service -attribute_name service_type

#     # send mail service
#     content::type::attribute::delete -content_type imsld_send_mail_service -attribute_name service_id
#     content::type::attribute::delete -content_type imsld_send_mail_service -attribute_name recipients
#     content::type::attribute::delete -content_type imsld_send_mail_service -attribute_name is_visible_p
#     content::type::attribute::delete -content_type imsld_send_mail_service -attribute_name parameters

#     # send mail data
#     content::type::attribute::delete -content_type imsld_send_mail_data -attribute_name send_mail_id
#     content::type::attribute::delete -content_type imsld_send_mail_data -attribute_name role_id
#     content::type::attribute::delete -content_type imsld_send_mail_data -attribute_name mail_data
    
#     # conference service
#     content::type::attribute::delete -content_type imsld_conference_service -attribute_name service_id
#     content::type::attribute::delete -content_type imsld_conference_service -attribute_name conference_type
#     content::type::attribute::delete -content_type imsld_conference_service -attribute_name imsld_item_id
#     content::type::attribute::delete -content_type imsld_conference_service -attribute_name manager_id

#     # methods
#     content::type::attribute::delete -content_type imsld_method -attribute_name imsld_id
#     content::type::attribute::delete -content_type imsld_method -attribute_name time_limit_id
#     content::type::attribute::delete -content_type imsld_method -attribute_name on_completion_id

#     # plays
#     content::type::attribute::delete -content_type imsld_play -attribute_name method_id
#     content::type::attribute::delete -content_type imsld_play -attribute_name is_visible_p
#     content::type::attribute::delete -content_type imsld_play -attribute_name identifier
#     content::type::attribute::delete -content_type imsld_play -attribute_name when_last_act_completed_p
#     content::type::attribute::delete -content_type imsld_play -attribute_name time_limit_id
#     content::type::attribute::delete -content_type imsld_play -attribute_name on_completion_id

#     # acts
#     content::type::attribute::delete -content_type imsld_act -attribute_name play_id
#     content::type::attribute::delete -content_type imsld_act -attribute_name time_limit_id
#     content::type::attribute::delete -content_type imsld_act -attribute_name identifier
#     content::type::attribute::delete -content_type imsld_act -attribute_name on_completion_id

#     # role parts
#     content::type::attribute::delete -content_type imsld_role_part -attribute_name identifier
#     content::type::attribute::delete -content_type imsld_role_part -attribute_name role_id
#     content::type::attribute::delete -content_type imsld_role_part -attribute_name learning_activity_id
#     content::type::attribute::delete -content_type imsld_role_part -attribute_name support_activity_id
#     content::type::attribute::delete -content_type imsld_role_part -attribute_name activity_structure_id
#     content::type::attribute::delete -content_type imsld_role_part -attribute_name environment_id

#     # parameters
#     content::type::attribute::delete -content_type imsld_parameter -attribute_name value

#     # time limits
#     content::type::attribute::delete -content_type imsld_time_limit -attribute_name time_in_seconds

#     # on completion
#     content::type::attribute::delete -content_type imsld_on_completion -attribute_name feedback_title

#     ### IMS-LD Content Packaging
    
#     # manifests
#     content::type::attribute::delete -content_type imsld_cp_manifest -attribute_name identifier
#     content::type::attribute::delete -content_type imsld_cp_manifest -attribute_name version
#     content::type::attribute::delete -content_type imsld_cp_manifest -attribute_name parent_manifest_id
#     content::type::attribute::delete -content_type imsld_cp_manifest -attribute_name is_shared_p

#     # organizations
#     content::type::attribute::delete -content_type imsld_cp_organization -attribute_name manifest_id

#     # resources
#     content::type::attribute::delete -content_type imsld_cp_resource -attribute_name manifest_id
#     content::type::attribute::delete -content_type imsld_cp_resource -attribute_name identifier
#     content::type::attribute::delete -content_type imsld_cp_resource -attribute_name type
#     content::type::attribute::delete -content_type imsld_cp_resource -attribute_name href

#     # dependencies
#     content::type::attribute::delete -content_type imsld_cp_dependency -attribute_name resource_id
#     content::type::attribute::delete -content_type imsld_cp_dependency -attribute_name identifierref

#     # imsld cp files
#     content::type::attribute::delete -content_type imsld_cp_file -attribute_name resource_id
#     content::type::attribute::delete -content_type imsld_cp_file -attribute_name path_to_file
#     content::type::attribute::delete -content_type imsld_cp_file -attribute_name file_name
#     content::type::attribute::delete -content_type imsld_cp_file -attribute_name href

#     content::type::delete -content_type imsld_learning_object -drop_table_p t 
#     content::type::delete -content_type imsld_imsld -drop_table_p t
#     content::type::delete -content_type imsld_learning_objective -drop_table_p t
#     content::type::delete -content_type imsld_prerequisite -drop_table_p t
#     content::type::delete -content_type imsld_item -drop_table_p t
#     content::type::delete -content_type imsld_component -drop_table_p t
#     content::type::delete -content_type imsld_role -drop_table_p t
#     content::type::delete -content_type imsld_prerequisite -drop_table_p t
#     content::type::delete -content_type imsld_activity_desc -drop_table_p t
#     content::type::delete -content_type imsld_learning_activity -drop_table_p t
#     content::type::delete -content_type imsld_support_activity -drop_table_p t
#     content::type::delete -content_type imsld_activity_structure -drop_table_p t
#     content::type::delete -content_type imsld_environment -drop_table_p t
#     content::type::delete -content_type imsld_service -drop_table_p t
#     content::type::delete -content_type imsld_send_mail_service -drop_table_p t
#     content::type::delete -content_type imsld_send_mail_data -drop_table_p t
#     content::type::delete -content_type imsld_conference_service -drop_table_p t
#     content::type::delete -content_type imsld_method -drop_table_p t
#     content::type::delete -content_type imsld_play -drop_table_p t
#     content::type::delete -content_type imsld_act -drop_table_p t
#     content::type::delete -content_type imsld_role_part -drop_table_p t
#     content::type::delete -content_type imsld_parameter -drop_table_p t
#     content::type::delete -content_type imsld_time_limit -drop_table_p t
#     content::type::delete -content_type imsld_on_completion -drop_table_p t

#     ### IMS-LD Content Packaging
#     content::type::delete -content_type imsld_cp_manifest -drop_table_p t
#     content::type::delete -content_type imsld_cp_organization -drop_table_p t
#     content::type::delete -content_type imsld_cp_resource -drop_table_p t
#     content::type::delete -content_type imsld_cp_dependency -drop_table_p t
#     content::type::delete -content_type imsld_cp_file -drop_table_p t


}