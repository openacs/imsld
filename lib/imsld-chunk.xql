<?xml version="1.0"?>
<queryset>



	<fullquery name="active_runs">
		<querytext>

        select run.run_id,
        coalesce(imsld.title, imsld.identifier) as imsld_title,
	    to_char(ao.creation_date,'MM/DD/YYYY HH24:MI') as creation_date
        from cr_items cr1, cr_items cr2, cr_items cr3, cr_items cr4, acs_objects ao,
        imsld_runs run, imsld_cp_manifests icm, imsld_cp_organizations ico, imsld_imsldsi imsld 
        where run.imsld_id = imsld.imsld_id
        and ao.object_id = run.run_id
        and cr1.live_revision = icm.manifest_id
        and cr1.parent_id = cr4.item_id
        and cr4.parent_id = :cr_root_folder_id
        and ico.manifest_id = cr1.item_id
        and imsld.organization_id = cr2.item_id
        and cr2.live_revision = ico.organization_id
        and cr3.live_revision = imsld.imsld_id
        and ( run.status = 'active' or run.status = 'stopped')
        $orderby

		</querytext>
	</fullquery>
</queryset>

