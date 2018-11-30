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
    {-prop ""}
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
    if { [string eq [content::item::get_content_type -item_id $file_id] "imsld_cp_file"] } {
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


ad_proc -callback as::session::update -impl imsld {
    -assessment_id
    -session_id
    -user_id
    -start_time
    -end_time
    -percent_score
    -elapsed_time
    -package_id
    -session_points
    -assessment_points
} {
   <p>Callback that updates a test's score in the course</p>

   @author Javier Morales Puerta (javomorales@gmail.es)
} {
    if { [catch {set resource_id [imsld::get_resource_from_object -object_id $assessment_id]} errmsg] } {
        ns_log notice "IMS-LD: QTI independent"
        return
    }
    
    # get the resource identifier
    set resource_ident [ db_string get_identifier {
        select identifier
	from imsld_cp_resources
	where resource_id = :resource_id
    } -default ""]
    
    set activity_list [lindex [imsld::get_activity_from_resource -resource_id $resource_id] 0]
    
    # set the activity_id, activity_item_id and activity_type
    set activity_id [lindex $activity_list 0]
    set activity_item_id [lindex $activity_list 1]
    set activity_type [lindex $activity_list 2]

    set imsld_id [imsld::get_imsld_from_activity -activity_id $activity_id -activity_type $activity_type]
    
    set aux "$resource_ident%"

    set item_prop_id [db_string get_property_id {
        select ip.item_id
	from imsld_propertiesi ip,
	imsld_componentsi ici,
	imsld_imsldsi iii,
	imsld_imslds ims
	where ip.component_id = ici.item_id
	and ici.imsld_id = iii.item_id
	and iii.revision_id = ims.imsld_id
	and ims.imsld_id = :imsld_id
	and ip.identifier like :aux
    }] 
    
    set property_id [content::item::get_live_revision -item_id $item_prop_id]

    set run_id [db_string get_run {
	select c.run_id 
	from acs_rels a, imsld_runs b, imsld_run_users_group_ext c
	where a.rel_type='imsld_run_users_group_rel' 
	and a.object_id_two=:user_id
	and b.imsld_id=:imsld_id
	and c.run_id=b.run_id
	and c.group_id=a.object_id_one
    }]

    ns_log notice "imsld::runtime::property::property_value_set -user_id $user_id -run_id $run_id -property_id $property_id -value $assessment_points"
    imsld::runtime::property::property_value_set -user_id $user_id -run_id $run_id -property_id $property_id -value $assessment_points

    ns_log notice " --- property updated --- "
    return
}
