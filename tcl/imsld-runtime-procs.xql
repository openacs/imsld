<?xml version="1.0"?>
<queryset>

    <fullquery name="imsld::runtime::property::instance_value_set.update_instance_value">
        <querytext>
            update imsld_property_instances
            set value = :value
            where instance_id = :instance_id
        </querytext>
	</fullquery>

</queryset>
