# /packages/imsld/tcl/imsld-runtime-procs

ad_library {
    Procedures in the imsld::runtime namespace.
    
    @creation-date Jun 2006
    @author jopez@inv.it.uc3m.es
    @cvs-id $Id$
}

namespace eval imsld {}
namespace eval imsld::runtime::property {}

ad_proc -public imsld::runtime::property::instance_value_set {
    -instance_id
    -value
} {
    db_dml update_instance_value { *SQL* }
}

