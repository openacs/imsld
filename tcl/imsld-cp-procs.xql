<?xml version="1.0"?>
<queryset>
	<fullquery name="imsld::cp::dependency_new.get_manifest">
		<querytext>
            select icr.manifest_id 
            from imsld_cp_resources icr, cr_items cri 
            where icr.resource_id = cri.live_revision
            and cri.item_id = :resource_id
        
		</querytext>
	</fullquery>
</queryset>

