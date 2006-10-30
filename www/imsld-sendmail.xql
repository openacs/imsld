<?xml version="1.0"?>
<queryset>

	<fullquery name="get_all_email_data">
		<querytext>
		select iri.title,
		       iri.role_id as group_recipient,
		       isms.recipients 
                from imsld_send_mail_datai ismd, 
		     acs_rels ar, 
		     imsld_send_mail_servicesi isms,
		     imsld_rolesi iri 
		where ismd.item_id=:send_mail_id 
		      and ar.object_id_two=ismd.item_id 
		      and ar.object_id_one=isms.item_id 
		      and iri.item_id=ismd.role_id
		</querytext>
	</fullquery>
    
</queryset>

