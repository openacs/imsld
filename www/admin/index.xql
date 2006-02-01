<?xml version="1.0"?>
<queryset>

	<fullquery name="get_imslds">
		<querytext>
    select imsld.imsld_id,
    coalesce(imsld.title, imsld.identifier) as imsld_title,
    cr3.item_id,
    cr3.live_revision
    from cr_items cr1, cr_items cr2, cr_items cr3, cr_items cr4,
    imsld_cp_manifests icm, imsld_cp_organizations ico, imsld_imsldsi imsld 
    where cr1.live_revision = icm.manifest_id
    and cr1.parent_id = cr4.item_id
    and cr4.parent_id = :cr_root_folder_id
    and ico.manifest_id = cr1.item_id
    and imsld.organization_id = cr2.item_id
    and cr2.live_revision = ico.organization_id
    and cr3.item_id = imsld.item_id

		</querytext>
	</fullquery>
</queryset>

