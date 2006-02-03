<?xml version="1.0"?>
<queryset>

<fullquery name="callback::imsld::finish_object::impl::ld_resource.belongs_to_imsld">
	<querytext>
	select resource_id
    from imsld_cp_resources
    where acs_object_id=:object_id
          and type='imsqti_xmlv1p0'
	</querytext>
</fullquery>

</queryset>
