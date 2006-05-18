<?xml version="1.0"?>
<queryset>

	<fullquery name="get_recipients_info">
		<querytext>
        select person_id as user_id,
               first_names,
               last_name
        from persons
        where person_id in ([join $users_list ","])
		</querytext>
	</fullquery>
    
</queryset>

