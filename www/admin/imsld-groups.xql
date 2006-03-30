<?xml version="1.0"?>
<queryset>
	<fullquery name="get_groups_list">
		<querytext>
        select group_name,group_id
        from groups
        where group_name like ('%' || :role || '%')
		</querytext>
	</fullquery>
</queryset>
