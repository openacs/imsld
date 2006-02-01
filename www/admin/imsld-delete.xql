<?xml version="1.0"?>
<queryset>



	<fullquery name="delete_imsld">
		<querytext>
            update cr_items 
            set live_revision = NULL
            where item_id = (select item_id from cr_items where live_revision = :imsld_id)
        
		</querytext>
	</fullquery>

</queryset>

