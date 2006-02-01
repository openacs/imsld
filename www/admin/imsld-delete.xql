<?xml version="1.0"?>
<queryset>



	<fullquery name="get_grade_info">
		<querytext>
    select title as imsld_title
    from imsld_imsldsi
	where imsld_id = :imsld_id
		</querytext>
	</fullquery>
</queryset>

