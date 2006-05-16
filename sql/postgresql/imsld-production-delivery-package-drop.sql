-- P/pgLSQL packages for the production deivery datamodel
--
-- @author jopez@inv.it.uc3m.es
-- @creation-date May 2006

delete from acs_objects where object_type = 'imsld_run';

select acs_object_type__drop_type('imsld_run','f');

delete from acs_rels where rel_type = 'imsld_run_users_group_rel'; 

select acs_rel_type__drop_type('imsld_run_users_group_rel','t');

select acs_object_type__drop_type('imsld_run_users_group_rel','f');

drop function imsld_run__new (integer, integer, varchar, varchar, timestamptz, integer, varchar, integer, varchar);

drop function imsld_run__del (integer);

drop function imsld_property_instance__new (integer, integer, integer, integer, varchar);

drop function imsld_property_instance__del (integer);

drop function imsld_attribute_instance__new (integer, integer, varchar, varchar, integer, varchar);

drop function imsld_attribute_instance__del (integer);


