-- P/pgLSQL packages for the production deivery datamodel
--
-- @author jopez@inv.it.uc3m.es
-- @creation-date Abr 2006

select acs_object_type__create_type (
    'imsld_run', 	    --object type
    'IMS-LD Run',   	--pretty name
    'IMS-LD Runss',  	--pretty prural
    'acs_object',  		--supertype
    'imsld_runs',  	    --table_name
    'run_id',  	  		--id_column
    null,  				--package_name
    'f',  				--abstract_p
    null,  				--type_extension_table
    null  				--name_method
);

insert into acs_object_type_tables
    (object_type, table_name, id_column)
    values
    ('imsld_run', 'imsld_runs', 'run_id');

select acs_attribute__create_attribute (	
	'imsld_run', 	    --object_type
	'imsld_id', 		--oattribute_name
	'integer', 			--datatype
	'IMS-LD id', 		--pretty_name
	'IMS-LD ids', 		--pretty_plural
	'imsld_runs', 	    --table_name
	'imsld_id',			--column_name
	null,				--default_value
	1, 					--min_n_values
	1, 					--max_n_values
	null, 				--sort_order
	'type_specific', 	--storage
	'f' 				--static_p
);

select acs_attribute__create_attribute (	
	'imsld_run', 	    --object_type
	'status',   		--oattribute_name
	'string', 			--datatype
	'Status', 		    --pretty_name
	'Status', 		    --pretty_plural
	'imsld_runs', 	    --table_name
	'status',			--column_name
	null,				--default_value
	1, 					--min_n_values
	1, 					--max_n_values
	null, 				--sort_order
	'type_specific', 	--storage
	'f' 				--static_p
);

select define_function_args('imsld_run__new','run_id,imsld_id,status,object_type,creation_date,creatrion_user,creation_ip,context_id,title');
create or replace function imsld_run__new (
    integer,        -- run_id
    integer,        -- imsld_id
    varchar,        -- status
    varchar,        -- object_type
    timestamptz,    -- creation_date
    integer,        -- creation_user
    varchar,        -- creation_ip
    integer,        -- context_id
    varchar         -- title
)
returns integer as '
declare
    p_run_id alias for $1; -- default null,
    p_imsld_id alias for $2;
    p_status alias for $3;
    p_object_type alias for $4; -- default ''imsld_run''
    p_creation_date alias for $5; -- default now()
    p_creation_user alias for $6; -- default null
    p_creation_ip alias for $7; -- default null
    p_context_id alias for $8; -- default null
    p_title alias for $9; -- default null

    v_run_id        integer;
    v_object_type   varchar;  

begin
    if p_object_type is null then
        v_object_type := ''imsld_run'';
    else
        v_object_type := p_object_type;
    end if;

    -- Instantiate the ACS Object super type 
    v_run_id  := acs_object__new(
        p_run_id,
        v_object_type,
        p_creation_date,
        p_creation_user,
        p_creation_ip,
        p_context_id,
        ''t'',
        p_title,
        null
    );

    insert into imsld_runs (run_id, imsld_id, status)
    values (v_run_id, p_imsld_id, p_status);

   return v_run_id;
end;
' language 'plpgsql';

create or replace function imsld_run__del (integer)
returns integer as '
declare
  p_run_id            alias for $1;
begin
  perform acs_object__delete(p_run_id);

  return 0; 
end;' language 'plpgsql';

select define_function_args('imsld_property_instance__new','instance_id,property_id,identifier,party_id,run_id,value');
create or replace function imsld_property_instance__new (
    integer,        -- instance_id
    integer,        -- property_id
    varchar,        -- identifier
    integer,        -- party_id
    integer,        -- run_id
    varchar         -- value
)
returns integer as '
declare
    p_property_instance_id alias for $1; -- default null
    p_property_id alias for $2;
    p_identifier alias for $3;
    p_party_id alias for $4; -- default null
    p_run_id alias for $5;
    p_value alias for $6; -- default ''<no value>''

    v_property_instance_id        integer;

begin
    
    select acs_object_id_seq.nextval
    into v_property_instance_id from dual;

    insert into imsld_property_instances (instance_id, property_id, identifier, party_id, run_id, value)
    values (v_property_instance_id, p_property_id, p_identifier, p_party_id, p_run_id, p_value);


    return v_property_instance_id;
end;
' language 'plpgsql';

create or replace function imsld_property_instance__del (integer)
returns integer as '
declare
  p_property_instance_id            alias for $1;
begin
    delete from imsld_property_instances
    where instance_id = p_property_instance_id;
    
    return 0; 
end;' language 'plpgsql';

select define_function_args('imsld_attribute_instance__new','instance_id,owner_id,type,name,run_id,is_visible_p');
create or replace function imsld_attribute_instance__new (
    integer,        -- instance_id
    integer,        -- owner_id
    varchar,        -- type
    varchar,        -- name
    integer,        -- run_id
    varchar         -- is_visible_p
)
returns integer as '
declare
    p_instance_id alias for $1; -- default null
    p_owner_id alias for $2;
    p_type alias for $3;
    p_name alias for $4;
    p_run_id alias for $5;
    p_is_visible_p alias for $6;

    v_attribute_instance_id        integer;

begin
    
    select acs_object_id_seq.nextval
    into v_attribute_instance_id from dual;

    insert into imsld_attribute_instances (instance_id, owner_id, type, name, run_id, is_visible_p)
    values (v_attribute_instance_id, p_owner_id, p_type, p_name, p_run_id, p_is_visible_p);

    return v_attribute_instance_id;
end;
' language 'plpgsql';

create or replace function imsld_attribute_instance__del (integer)
returns integer as '
declare
  p_instance_id            alias for $1;
begin
    delete from imsld_attribute_instances
    where instance_id = p_instance_id;
    
    return 0; 
end;' language 'plpgsql';

