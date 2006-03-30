<?xml version="1.0"?>
<queryset>
	<fullquery name="get_imslds_from_manifest">
		<querytext>
        select ii.imsld_id 
        from imsld_cp_organizationsi icoi,
             imsld_imslds ii 
        where icoi.item_id=ii.organization_id 
              and icoi.manifest_id = :manifest_id
		</querytext>
	</fullquery>
</queryset>

