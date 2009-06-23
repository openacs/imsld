--
-- GSI Data Model Drop(services for IMS LD)
--
-- @author lfuente@it.uc3m.es
-- @creation-date nov-2008
--


drop table imsld_gsi_services cascade;
drop table imsld_gsi_alternatives cascade;
drop table imsld_gsi_groups cascade;
drop table imsld_gsi_tools cascade;
drop table imsld_gsi_permissions cascade;
drop table imsld_gsi_data cascade;
drop table imsld_gsi_keywords cascade;
drop table imsld_gsi_constraints cascade;
drop table imsld_gsi_triggers cascade;
drop table imsld_gsi_function_usage_set cascade;
drop table imsld_gsi_function_params cascade;
drop table imsld_gsi_functions cascade;

drop table imsld_gsi_trigger_constraint_rels cascade;
drop table imsld_gsi_tools_permissions_rels cascade;
drop table imsld_gsi_tools_functions_rels cascade;
drop table imsld_gsi_keywords_tools_rels cascade;
drop table imsld_gsi_groups_roles_rels cascade;
