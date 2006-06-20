# packages/imsld/www/properties-value-set.tcl

ad_page_contract {
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
        imsld::runtime::property::instance_value_set -instance_id $instance_id -value $value
    }
}

ad_returnredirect "$return_url"

