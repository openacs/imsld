# packages/imsld/www/properties-value-set.tcl

ad_page_contract {
    Sets the property value through a function call
} {
    instances_ids:array
    return_url
    owner_id
} -validate {
    no_instance {
        if { [array size instances_ids] == 0 } {
            ad_complain "[_ imsld.lt_Please_submit_a_value]"
        }
    }
}

foreach instance_id [array names instances_ids -regexp {[^[:alpha:]]$}] {
    if { [info exists instances_ids($instance_id)] } {
        # avoiding hacks
        db_1row instance_info_id {
            select ins.property_id,
            ins.run_id,
	    prop.datatype
            from imsld_property_instances ins,
	    imsld_properties prop
            where ins.instance_id = :instance_id
	    and ins.property_id = prop.property_id
        }
	
	if { [string eq "file" $datatype] } {
	    imsld::runtime::property::property_value_set -run_id $run_id \
		-user_id $owner_id \
		-value $instances_ids($instance_id) \
		-property_id $property_id \
		-upload_file $instances_ids($instance_id) \
		-tmpfile $instances_ids(${instance_id}.tmpfile)
	} else {
	    imsld::runtime::property::property_value_set -run_id $run_id \
		-user_id $owner_id \
		-value $instances_ids($instance_id) \
		-property_id $property_id
	}
    }
}

ad_returnredirect "$return_url"

