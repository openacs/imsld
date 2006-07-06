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
namespace eval imsld::runtime::class {}
namespace eval imsld::runtime::isvisible {}
namespace eval imsld::runtime::activity_structure {}
namespace eval imsld::runtime::environment {}

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
    Sets a property to the given value. If some restriction is violated returns 0 and an explanation.
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

    # validate against restrictions
    set enumeration_list [list]
    db_foreach restriction {
        select restriction_type,
        value as restriction_value
        from imsld_restrictions
        where property_id = :property_id
    } {
        switch $restriction_type {
            length {
                if { [length $value] <> $restriction_value } {
                    return [list 0 "<#_ The length must be %restriction_value% #>"]
                }
            }
            minLength {
                if { [length $value] < $restriction_value } {
                    return [list 0 "<#_ The length must be greather than %restriction_value%  #>"]
                }
            }
            maxLength {
                if { [length $value] > $restriction_value } {
                    return [list 0 "<#_ The length must be lower than %restriction_value% #>"]
                }
            }
            enumeration {
                lappend enumeration_list $restriction_value
            }
            maxInclusive {
                if { $value > $restriction_value } {
                    return [list 0 "<#_ The value must be lower than %restriction_value% (inclusive #>"]
                }
            }
            minInclusive {
                if {$value < $restriction_value } {
                    return [list 0 "<#_ The value must be greather than %restriction_value% (inclusive) #>"]
                }
            }
            maxExclusive {
                if { $value >= $restriction_value } {
                    return [list 0 "<#_ The value must be lower than %restriction_value% #>"]
                }
            }
            minExclusive {
                if { $value <= $restriction_value } { 
                    return [list 0 "<#_ The value must be greather than %restriction_value% #>"]
                }
            }
            totalDigits {
                if { [expr int($value)] <> $restriction_value } {
                    return [list 0 "<#_ The integer part can't have more than %restriction_value% digits #>"]
                }
            }
            fractionDigits {
                if { [expr [string length "$value"] - [string last "." "$value"] - 1] > $restriction_value } {
                    return [list 0 "<#_ The decimal digits can't be more than %restriction_value% #>"]
                }
            }
            pattern {
                if { ![regexp "$restriction_value" $value] } {
                    return [list 0 "<#_ The value (%value%) doesn't match with the expression %restriction_value% #>"]
                }
            }
        }
    }

    if { [llength $enumeration_list] && [lsearch -exact $enumeration_list $value] == -1 } {
        return [list 0 "<#_ The value %value% is not alowed  #>"]
    }

    
    # instance info
    set role_instance_id ""
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

    imsld::condition::execute_all -run_id $run_id
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

    set role_instance_id ""
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
    return $value
}

ad_proc -public imsld::runtime::class::show_hide {
    -run_id
    -class
    {-title ""}
    {-with_control_p ""}
    -action:required
} {
    mark a class as showh or hidden. NOTE: not recursively
} {
    if { [string eq $action "show"] } {
        set is_visible_p "t"
    } else {
        set is_visible_p "f"
    }

    db_dml set_class_shown_hidden { *SQL* }        
}

ad_proc -public imsld::runtime::isvisible::show_hide {
    -run_id
    -identifier
    -action_required
} {
    mark a isvisible as showh. NOTE: not recursively
} {
    if { [string eq $action "show"] } {
        set is_visible_p "t"
    } else {
        set is_visible_p "f"
    }
    db_dml set_isvisible_shown_hidden { *SQL* }
}

ad_proc -public imsld::runtime::environment::show_hide {
    -run_id
    -identifier
    -action
} {
    mark an environment as showh or hidden. NOTE: not recursively
} {
    # according to the spec, the environments doesn't have any isvisible attribute
    # so we show the referenced learning objects and services

    db_1row context_info {
        select env.environment_id,
        env.item_id as environment_item_id,
        comp.component_id,
        comp.item_id as component_item_id
        from imsld_runs ir, imsld_componentsi comp, imsld_environmentsi env, imsld_imsldsi
        where ir.run_id = :run_id
        and ir.imsld_id = ii.imsld_id
        and ii.item_id = comp.imsld_id
        and env.identifier = :identifier
        and env.component_id = comp.item_id
    }
    
    # 1. show the learning objects
    db_foreach learning_object {
        select lo.learning_object_id,
        lo.identifier as lo_identifier
        from imsld_learning_objects lo, imsld_environmentsi env
        where lo.environment_id = :environment_item_id
    } {
        imsld::runtime::isvisible::show_hide -run_id $run_id -identifier $lo_identifier -action $action
    }

    # 2. show the services
    db_foreach service {
        select serv.service_id,
        serv.identifier as serv_identifier
        from imsld_services serv
        where serv.environment_id = :environment_item_id
    } {
        imsld::runtime::isvisible::show_hide -run_id $run_id -identifier $serv_identifier -action $action
    }
    
}

ad_proc -public imsld::runtime::activity_structure::show_hide {
    -run_id
    -identifier
    -action
} {
    mark an activity structure as showh or hidden. NOTE: not recursively
} {
    # according to the spec, the activity structures doesn't have any isvisible attribute
    # so we show the referenced activities, learning infos and environments

    db_1row context_info {
        select isa.structure_id,
        isa.item as structure_item_id
        from imsld_runs ir, imsld_componentsi comp, imsld_activity_structuresi isa, imsld_imsldsi
        where ir.run_id = :run_id
        and ir.imsld_id = ii.imsld_id
        and ii.item_id = comp.imsld_id
        and isa.identifier = :identifier
        and isa.component_id = comp.item_id
    }
    
    # 1. show the info
    db_foreach information {
        select ii.imsld_item_id,
        ii.identifier as ii_identifier
        from acs_rels ar, imsld_itemsi ii
        where ar.object_id_one = :structure_item_id
        and ar.object_id_two = ii.item_id
    } {
        imsld::runtime::isvisible::show -run_id $run_id -identifier $ii_identifier -action $action
    }

    # 2. show the learning activities
    db_foreach learning_activity {
        select la.item_id as activity_item_id,
        la.identifier as la_identifier
        from imsld_learning_activitiesi, acs_rels ar
        where ar.object_id_one = :structure_item_id
        and ar.object_id_two = la.item_id
    } {
        imsld::runtime::isvisible::show -run_id $run_id -identifier $la_identifier -action $action
    }

    # 3. show the support activities
    db_foreach support_activity {
        select sa.item_id as activity_item_id,
        sa.identifier as sa_identifier
        from imsld_support_activitiesi, acs_rels ar
        where ar.object_id_one = :structure_item_id
        and ar.object_id_two = sa.item_id
    } {
        imsld::runtime::isvisible::show -run_id $run_id -identifier $sa_identifier -action $action
    }

    # 4. show the activity structures
    db_foreach structure {
        select ias.item_id as structure_item_id,
        ias.identifier as structure_identifier
        from imsld_activity_structuresi, acs_rels ar
        where ar.object_id_one = :structure_item_id
        and ar.object_id_two = ias.item_id
    } {
        imsld::runtime::isvisible::show -run_id $run_id -identifier $structure_identifier -action $action
    }

    # 5. show the environments
    db_foreach structure {
        select env.item_id as env_item_id,
        env.identifier as env_identifier
        from imsld_environmentsi, acs_rels ar
        where ar.object_id_one = :structure_item_id
        and ar.object_id_two = env.item_id
    } {
        imsld::runtime::isvisible::show -run_id $run_id -identifier $structure_identifier -action $action
    }
    
}

