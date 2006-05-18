<?xml version="1.0"?>
<queryset>

	<fullquery name="get_all_email_data">
		<querytext>

        select iri.title,
               iri.role_id as group_recipient,
               isms.recipients 
        from imsld_send_mail_data ismd,
             imsld_send_mail_servicesi isms, 
             imsld_rolesi iri 
        where ismd.send_mail_id=isms.item_id 
              and iri.item_id=ismd.role_id
              and isms.mail_id=:send_mail_id
		</querytext>
	</fullquery>
    
</queryset>

