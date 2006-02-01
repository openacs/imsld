<?xml version="1.0"?>
<queryset>


	<fullquery name="imsld::cr::file_new.file_exists">
		<querytext>
            select 1 
            from imsld_cp_files icf, cr_items cri
            where cri.item_id = :item_id 
            and cri.live_revision = icf.imsld_file_id
		</querytext>
	</fullquery>
</queryset>

