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

#     if {[db_0or1row belongs_to_imsld {} ] } {
#         set resource_id [imsld::get_resource_from_object -object_id $object_id]
#         imsld::finish_resource -resource_id $resource_id
#     }
} 

ad_proc -public -callback fs::file_revision_new -impl imsld {
    {-package_id:required}
    {-file_id:required}
    {-parent_id:required}
} { 
    For each new file of type imsld_cp_file, the new revision of this content type must be created.

    This is a hack so let the course administrator can change the files of the UoL from the fs UI. This should be done in a cleaner way.
} {
    if { [string eq [content::item::content_type -item_id $file_id] "imsld_cp_file"] } {
	db_transaction {
	    db_1row imsld_cp_file_info {
		select path_to_file,
		file_name,
		href,
		imsld_file_id
		from imsld_cp_filesi
		where item_id = :file_id
	    }
	    db_1row revision_info {
		select mime_type, revision_id
		from cr_revisions
		where item_id = :file_id
		and content_revision__is_live(revision_id) = 't'
	    }
	    db_dml update_cp_file_entry {
		update imsld_cp_files
		set imsld_file_id = :revision_id
		where imsld_file_id = :imsld_file_id
	    }
	}
    }
}

