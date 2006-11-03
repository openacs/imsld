<?xml version="1.0"?>
<queryset>

	<fullquery name="get_all_email_data">
		<querytext>
		select iri.title,
		       iri.role_id as group_recipient,
		       isms.recipients
           from imsld_send_mail_datai ismd, 
                imsld_send_mail_servicesi isms,
                acs_rels ar,
		     imsld_rolesi iri 
		where ar.object_id_two = ismd.item_id
        and ar.rel_type = 'imsld_send_mail_serv_data_rel'
        and ar.object_id_one = isms.item_id
        and isms.mail_id = :send_mail_id
        and iri.item_id = ismd.role_id

		</querytext>
	</fullquery>
    
</queryset>

