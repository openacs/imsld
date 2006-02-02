ad_library {
    Callback contract definitions for imsld.

    @author Eduardo Pérez Ureta (eduardo.perez@uc3m.es)
    @creation-date 2005-11-17
    @cvs-id $Id$
}

ad_proc -public -callback imsld::import {
    -res_type
    -res_href
    -tmp_dir
    -community_id
} {
    <p>Returns the acs_object_id for the resource.</p>

    @return a list with one element, the acs_object_id for the resource

    @author Eduardo Pérez Ureta (eduardo.perez@uc3m.es)
} -

ad_proc -public -callback imsld::finish_object -impl ld_resource {
    -object_id
} {
    <p>Tag a resource as finished into an activity.</p>

    @author Luis de la Fuente Valentín (lfuente@it.uc3m.es)
} {

    if {[db_0or1row belongs_to_imsld {} ] } {
        set resource_id [imsld::get_resource_from_object -object_id $object_id]
        imsld::finish_resource -resource_id $resource_id
    }
} 
