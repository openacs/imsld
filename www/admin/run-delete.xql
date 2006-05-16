<?xml version="1.0"?>
<queryset>



	<fullquery name="delete_run">
		<querytext>

        update imsld_runs
        set status = 'deleted'
        where run_id = :run_id
        
		</querytext>
	</fullquery>

</queryset>

