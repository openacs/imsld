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
