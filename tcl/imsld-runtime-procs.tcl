# /packages/imsld/tcl/imsld-runtime-procs

ad_library {
    Procedures in the imsld::runtime namespace.
    
    @creation-date Jun 2006
    @author jopez@inv.it.uc3m.es
    @cvs-id $Id$
}

namespace eval imsld {}
namespace eval imsld::runtime {}
namespace eval imsld::runtime::property {}

ad_proc -public imsld::runtime::property::instance_value_set {
    -instance_id
    -value
} {
    db_dml update_instance_value { *SQL* }
}

ad_proc -public imsld::runtime::property::property_value_set {
    -run_id
    -user_id
    -value
    {-identifier ""}
    {-property_id ""}
} {
    # context info
    db_1row context_info {
        select ic.item_id as component_item_id,
        ii.imsld_id,
        rug.group_id as run_group_id
        from imsld_componentsi ic, imsld_imsldsi ii, imsld_runs ir, imsld_run_users_group_ext rug
        where ic.imsld_id = ii.item_id
        and content_revision__is_live(ii.imsld_id) = 't'
        and ii.imsld_id = ir.imsld_id
        and rug.run_id = ir.run_id
        and ir.run_id = :run_id
    }

    # property info
    if { [string eq $property_id ""] } {
        db_1row property_info_from_identifier {
            select type,
            property_id,
            role_id
            from imsld_properties
            where component_id = :component_item_id
            and identifier = :identifier
        }
    } else {
        db_1row property_info_from_id {
            select type,
            identifier,
            role_id
            from imsld_properties
            where property_id = :property_id
        }
    }
    
    # instance info
    if { ![string eq $role_id ""] } {
        # find the role instance which the user belongs to
        set role_instance_id [imsld::roles::get_user_role_instance -run_id $run_id -role_id $role_id -user_id $user_id]
        if { !$role_instance_id } {
            # runtime error... the user doesn't belong to any role instance
            ns_log notice "User does not belong to any role instance"
            continue
        }
    }

    db_1row get_property_instance {
        select ins.instance_id
        from imsld_propertiesi prop,
        imsld_property_instances ins
        where prop.property_id = ins.property_id
        and ((prop.type = 'global')
             or (prop.type = 'loc' and ins.run_id = :run_id)
             or (prop.type = 'locpers' and ins.run_id = :run_id and ins.party_id = :user_id)
             or (prop.type = 'locrole' and ins.run_id = :run_id and ins.party_id = :role_instance_id)
             or (prop.type = 'globpers' and ins.party_id = :user_id))
        and prop.property_id = :property_id
    }
    imsld::runtime::property::instance_value_set -instance_id $instance_id -value $value
}

ad_proc -public imsld::runtime::time_uol_started {
    -run_id
} {
    return [db_string date_time { *SQL* }]
}

ad_proc -public imsld::runtime::date_time_activity_started {
    -run_id
    -user_id
    -activity_id
} {
    return [db_string date_time { *SQL* }]
}

ad_proc -public imsld::runtime::property::property_value_get {
    -run_id
    -user_id
    {-identifier ""}
    {-property_id ""}
} {
    # context info
    db_1row context_info {
        select ic.item_id as component_item_id,
        ii.imsld_id,
        rug.group_id as run_group_id
        from imsld_componentsi ic, imsld_imsldsi ii, imsld_runs ir, imsld_run_users_group_ext rug
        where ic.imsld_id = ii.item_id
        and content_revision__is_live(ii.imsld_id) = 't'
        and ii.imsld_id = ir.imsld_id
        and rug.run_id = ir.run_id
        and ir.run_id = :run_id
    }

    # property info
    if { [string eq $property_id ""] } {
        db_1row property_info_from_identifier {
            select type,
            property_id,
            role_id
            from imsld_properties
            where component_id = :component_item_id
            and identifier = :identifier
        }
    } else {
        db_1row property_info_from_id {
            select type,
            identifier,
            role_id
            from imsld_properties
            where property_id = :property_id
        }
    }

    if { ![string eq $role_id ""] } {
        # find the role instance which the user belongs to
        set role_instance_id [imsld::roles::get_user_role_instance -run_id $run_id -role_id $role_id -user_id $user_id]
        if { !$role_instance_id } {
            # runtime error... the user doesn't belong to any role instance
            ns_log notice "User does not belong to any role instance"
            continue
        }
    }

    db_1row get_property_value {
        select ins.property_id,
        prop.datatype,
        coalesce(ins.value, prop.initial_value) as value
        from imsld_propertiesi prop,
        imsld_property_instances ins
        where prop.property_id = ins.property_id
        and ((prop.type = 'global')
             or (prop.type = 'loc' and ins.run_id = :run_id)
             or (prop.type = 'locpers' and ins.run_id = :run_id and ins.party_id = :user_id)
             or (prop.type = 'locrole' and ins.run_id = :run_id and ins.party_id = :role_instance_id)
             or (prop.type = 'globpers' and ins.party_id = :user_id))
        and prop.property_id = :property_id
    }
}



