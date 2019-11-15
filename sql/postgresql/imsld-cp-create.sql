--
-- IMS-LD Package Data Model (Content Packagin) Create
--
-- @author jopez@inv.it.uc3m.es
-- @creation-date jul-2005
--

-- Manifests
create table imsld_cp_manifests (
    manifest_id         integer
                        constraint imsld_man_fk
                        references cr_revisions
                        on delete cascade
                        constraint imsld_man_pk
                        primary key,
    identifier          varchar(1000),
    version             varchar(100),
    is_shared_p         char(1)
                        check (is_shared_p in ('t','f'))   
                        default 't',  
    -- A manifest could have multiple submanifests
    parent_manifest_id  integer
);

-- create index for imsld_cp_organizations
create index imsld_cp_manifests_man_id_idx on imsld_cp_manifests(parent_manifest_id);

comment on table imsld_cp_manifests is '
This table stores all the available manifests (that could be courses) in the system.';

comment on column imsld_cp_manifests.identifier is '
Manifest identifier
Identifier get from the imsmanifest.xml file. ';

comment on column imsld_cp_manifests.parent_manifest_id is '
Parent manifest.
A manifest could have submanifests. If the manifest doesn't have a parent
then we put 0';

comment on column imsld_cp_manifests.is_shared_p is '
This field indicates if the manifest can be shared between other dotLRN classes';

-- Organizations
create table imsld_cp_organizations (
    organization_id integer
                    constraint imsld_cp_org_fk
                    references cr_revisions
                    on delete cascade
                    constraint imsld_cp_org_pk
                    primary key,
    manifest_id     integer
                    constraint imsld_cp_org_man_id_fk
                    references cr_items
);

-- create index for imsld_cp_organizations
create index imsld_cp_organizations_man_id_idx on imsld_cp_organizations(manifest_id);

-- Resources
create table imsld_cp_resources (
    resource_id     integer
                    constraint imsld_cp_resources_fk
                    references cr_revisions
                    on delete cascade
                    constraint imsld_cp_resources_pk
                    primary key,
    manifest_id     integer
                    constraint imsld_cp_resources_man_id_fk
                    references cr_items
                    on delete cascade,
    identifier      varchar(100),
    type            varchar(1000),
    href            varchar(2000),
    -- pointer to the dotLRN services
    acs_object_id   integer
                    constraint imsld_cp_resources_ob_id_fk
                    references acs_objects
                    on delete cascade
);

-- create index for imsld_cp_resources
create index imsld_cp_resources_man_id_idx on imsld_cp_resources(manifest_id);
create index imsld_cp_resources_obj_id_idx on imsld_cp_resources(acs_object_id);

comment on column imsld_cp_resources.acs_object_id is '
This field is used to map the resource with a dotLRN service. 
The dotLRN service which the object_id points to depends on the resource_type.';

-- Resource dependencies
create table imsld_cp_dependencies (
    dependency_id   integer
                    constraint imsld_cp_dependencies_fk
                    references cr_revisions
                    on delete cascade
                    constraint imsld_cp_dependencies_pk
                    primary key,
    resource_id     integer
                    constraint imsld_cp_dependencies_res_id_fk
                    references cr_items,
    identifierref   varchar(2000)
);

-- create index for imsld_cp_dependencies
create index imsld_cp_dependencies_res_id_idx on imsld_cp_dependencies(resource_id);

-- Resource files
create table imsld_cp_files (
    imsld_file_id   integer
                    constraint imsld_cp_files_fk
                    references cr_revisions(revision_id)
                    on delete cascade
                    constraint imsld_cp_files_pk
                    primary key,
    path_to_file    varchar(2000),
    file_name        varchar(2000),
    href            varchar(2000)
);
    


