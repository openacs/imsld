# packages/imsld/www/properties-value-set.tcl

ad_page_contract {
    Sets the property value through a function call
} {
    instances_ids:array,notnull
    return_url
} -validate {
    no_instance {
        if { [array size instances_ids] == 0 } {
            ad_complain "[_ imsld.lt_Please_submit_a_value]"
        }
    }
}

foreach instance_id [array names instances_ids] {
    if { [info exists instances_ids($instance_id)] } {
        # avoiding hacks
        set value $instances_ids($instance_id)
        db_1row instance_info_id {
            select property_id,
            run_id
            from imsld_property_instances
            where instance_id = :instance_id
        }
        imsld::runtime::property::property_value_set -run_id $run_id -user_id [ad_conn user_id] -value $value -property_id $property_id
    }
}

ad_returnredirect "$return_url"

