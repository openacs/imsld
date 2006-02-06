# /packages/imsld/tcl/imsld-procs.tcl

ad_library {
    Procedures in the imsld namespace.
    
    @creation-date Aug 2005
    @author jopez@inv.it.uc3m.es
    @cvs-id $Id$
}

namespace eval imsld {}

ad_proc -public imsld::safe_url_name { 
    -name:required
} { 
    returns the filename replacing some characters
} {  
    regsub -all {[<>:\"|/@\\\#%&+\\ ,\?]} $name {_} name
    return $name
} 

ad_proc -public imsld::package_key { 
} { 
    returns the package_key of the IMS-LD package
} {  
    return imsld
} 

ad_proc -public imsld::object_type_image_path {
    -object_type
} { 
    returns the path to the image representing the given object_type in the imsld package
} { 
    switch $object_type {
        forums_forum {
            set image_path "[lindex [site_node::get_url_from_object_id -object_id [ad_conn package_id]] 0][imsld::package_key]/resources/forums.png"
        }
        as_assessments {
            set image_path "[lindex [site_node::get_url_from_object_id -object_id [ad_conn package_id]] 0][imsld::package_key]/resources/assessment.png"
        }
        ims_manifest_object {
            set image_path "[lindex [site_node::get_url_from_object_id -object_id [ad_conn package_id]] 0][imsld::package_key]/resources/lors.png"
        }
        default {
            set image_path "[lindex [site_node::get_url_from_object_id -object_id [ad_conn package_id]] 0][imsld::package_key]/resources/file-storage.png"
        }
    }
    return $image_path
} 

ad_proc -public imsld::get_role_part_from_activity {
    -activity_type
    -leaf_id
} { 
    @return A the role_part_id that references the passed activity_item_id (leaf_id)
} {
    switch $activity_type {
        learning {
            if { [db_0or1row directly_mapped {
                select item_id as rp_item_id, role_part_id
                from imsld_role_partsi
                where learning_activity_id = :leaf_id
            }] } {
                return $role_part_id
            }
           # the learning activity is referenced by an activity structure... digg more
            db_1row get_la_activity_structure {
                select ias.structure_id, ias.item_id as leaf_id
                from imsld_activity_structuresi ias, acs_rels ar, imsld_learning_activitiesi la
                where ar.object_id_one = ias.item_id
                and ar.object_id_two = la.item_id
                and content_revision__is_live(ias.structure_id) = 't'
                and la.item_id = :leaf_id
            }
            return [imsld::get_role_part_from_activity -activity_type structure -leaf_id $leaf_id]
        }
        support {
            if { [db_0or1row directly_mapped {
                select item_id as rp_item_id, role_part_id
                from imsld_role_partsi
                where support_activity_id = :leaf_id
            }] } {
                return $role_part_id
            }
            # the support activity is referenced by an activity structure... digg more
            db_1row get_sa_activity_structure {
                select ias.structure_id, ias.item_id as leaf_id
                from imsld_activity_structuresi ias, acs_rels ar, imsld_learning_activitiesi sa
                where ar.object_id_one = ias.item_id
                and ar.object_id_two = sa.item_id
                and content_revision__is_live(ias.structure_id) = 't'
                and la.item_id = :leaf_id
            }
            return [imsld::get_role_part_from_activity -activity_type structure -leaf_id $leaf_id]
        }
        structure {
            if { [db_0or1row directly_mapped {
                select item_id as rp_item_id, role_part_id
                from imsld_role_partsi
                where activity_structure_id = :leaf_id
            }] } {
                return $role_part_id
            }
            # the activity structure is referenced by an activity structure... digg more
            db_1row get_as_activity_structure {
                select ias.structure_id, ias.item_id as structure_item_id
                from imsld_activity_structuresi ias, acs_rels ar
                where ar.object_id_one = ias.item_id
                and ar.object_id_two = :leaf_id
                and content_revision__is_live(ias.structure_id) = 't'
            }
            return [imsld::get_role_part_from_activity -activity_type structure -leaf_id $leaf_id]
        }
    }
} 

ad_proc -public imsld::community_id_from_manifest_id {
    -manifest_id:required
} { 
    returns the community_id using the manifest_id to search for it
} {  
    return [db_string get_community_id {
        select dc.community_id
        from imsld_cp_manifestsi im, acs_objects ao, dotlrn_communities dc
        where im.object_package_id = ao.package_id
        and ao.context_id = dc.package_id
        and im.manifest_id = :manifest_id
    }]
} 

ad_proc -public imsld::sweep_expired_activities { 
} { 
    Sweeps the methods, plays, acts  and activities marking as finished the ones that already have been expired according with the value of time-limit.
} {
    # 1. methods
    foreach referenced_method [db_list_of_lists possible_expired_method {
        select icm.manifest_id,
        ii.imsld_id,
        im.method_id, 
        ca.time_in_seconds,
        icm.creation_date
        from imsld_cp_manifestsi icm, imsld_cp_organizationsi ico, 
        imsld_imsldsi ii, imsld_methodsi im, imsld_complete_actsi ca
        where im.imsld_id = ii.item_id
        and ii.organization_id = ico.item_id
        and ico.manifest_id = icm.item_id
        and im.complete_act_id = ca.item_id
        and ca.time_in_seconds is not null
        and content_revision__is_live(im.method_id) = 't'
    }] {
        set manifest_id [lindex $referenced_method 0]
        set imsld_id [lindex $referenced_method 1]
        set method_id [lindex $referenced_method 2]
        set time_in_seconds [lindex $referenced_method 3]
        set creation_date [lindex $referenced_method 4]
        if { [db_0or1row compre_times {
            select 1
            where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
        }] } {
            # the method has been expired, let's mark it as finished 
            set community_id [imsld::community_id_from_manifest_id -manifest_id $manifest_id]
            db_foreach user_in_class {
                select app.user_id
                from dotlrn_member_rels_approved app
                where app.community_id = :community_id
                and app.member_state = 'approved'
            } {
                imsld::mark_method_finished -imsld_id $imsld_id \
                    -method_id $method_id \
                    -user_id $user_id
            }
        }
    }
    # 2. plays
    foreach referenced_play [db_list_of_lists possible_expired_plays {
        select icm.manifest_id,
        ii.imsld_id,
        ip.play_id,
        ca.time_in_seconds,
        icm.creation_date
        from imsld_cp_manifestsi icm, imsld_cp_organizationsi ico, 
        imsld_imsldsi ii, imsld_methodsi im, imsld_plays ip,
        imsld_complete_actsi ca
        where ip.method_id = im.item_id
        and im.imsld_id = ii.item_id
        and ii.organization_id = ico.item_id
        and ico.manifest_id = icm.item_id
        and ip.complete_act_id = ca.item_id
        and ca.time_in_seconds is not null
        and content_revision__is_live(ip.play_id) = 't'
    }] {
        set manifest_id [lindex $referenced_play 0]
        set imsld_id [lindex $referenced_play 1]
        set play_id [lindex $referenced_play 2]
        set time_in_seconds [lindex $referenced_play 3]
        set creation_date [lindex $referenced_play 4]
        if { [db_0or1row compre_times {
            select 1
            where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
        }] } {
            # the play has been expired, let's mark it as finished 
            set community_id [imsld::community_id_from_manifest_id -manifest_id $manifest_id]
            db_foreach user_in_class {
                select app.user_id
                from dotlrn_member_rels_approved app
                where app.community_id = :community_id
                and app.member_state = 'approved'
            } {
                imsld::mark_play_finished -imsld_id $imsld_id \
                    -play_id $play_id \
                    -user_id $user_id
            }
        }
    }
    # 3. acts
    foreach referenced_act [db_list_of_lists possible_expired_acts {
        select icm.manifest_id,
        ii.imsld_id,
        ip.play_id,
        ia.act_id,
        ca.time_in_seconds,
        icm.creation_date
        from imsld_cp_manifestsi icm, imsld_cp_organizationsi ico, 
        imsld_imsldsi ii, imsld_methodsi im, imsld_playsi ip, imsld_acts ia,
        imsld_complete_actsi ca
        where ia.play_id = ip.item_id
        and ip.method_id = im.item_id
        and im.imsld_id = ii.item_id
        and ii.organization_id = ico.item_id
        and ico.manifest_id = icm.item_id
        and ia.complete_act_id = ca.item_id
        and ca.time_in_seconds is not null
        and content_revision__is_live(ia.act_id) = 't'
    }] {
        set manifest_id [lindex $referenced_act 0]
        set imsld_id [lindex $referenced_act 1]
        set play_id [lindex $referenced_act 2]
        set act_id [lindex $referenced_act 3]
        set time_in_seconds [lindex $referenced_act 4]
        set creation_date [lindex $referenced_act 5]
        if { [db_0or1row compre_times {
            select 1
            where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
        }] } {
            # the act has been expired, let's mark it as finished 
            set community_id [imsld::community_id_from_manifest_id -manifest_id $manifest_id]
            db_foreach user_in_class {
                select app.user_id
                from dotlrn_member_rels_approved app
                where app.community_id = :community_id
                and app.member_state = 'approved'
            } {
                imsld::mark_act_finished -imsld_id $imsld_id \
                    -play_id $play_id \
                    -act_id $act_id \
                    -user_id $user_id
            }
        }
    }

    # 4. support activities
    foreach referenced_sa [db_list_of_lists referenced_sas {
        select sa.item_id as sa_item_id,
        sa.activity_id,
        ca.time_in_seconds
        from imsld_support_activitiesi sa,
        imsld_complete_actsi ca
        where sa.complete_act_id = ca.item_id
        and content_revision__is_live(ca.complete_act_id) = 't'
        and ca.time_in_seconds is not null
    }] {
        set sa_item_id [lindex $referenced_sa 0]
        set activity_id [lindex $referenced_sa 1]
        set time_in_seconds [lindex $referenced_sa 2]
        set role_part_id [imsld::get_role_part_from_activity -activity_type support -leaf_id $sa_item_id]
        db_1row get_sa_activity_info {
            select icm.manifest_id,
            ii.imsld_id,
            ip.play_id,
            ia.act_id,
            icm.creation_date
            from imsld_cp_manifestsi icm, imsld_cp_organizationsi ico, 
            imsld_imsldsi ii, imsld_methodsi im, imsld_playsi ip, 
            imsld_actsi ia, imsld_role_partsi irp
            where irp.role_part_id = :role_part_id
            and irp.act_id = ia.item_id
            and ia.play_id = ip.item_id
            and ip.method_id = im.item_id
            and im.imsld_id = ii.item_id
            and ii.organization_id = ico.item_id
            and ico.manifest_id = icm.item_id
            and content_revision__is_live(icm.manifest_id) = 't'
        }
        if { [db_0or1row compre_times {
            select 1
            where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
        }] } {
            # the act has been expired, let's mark it as finished 
            set community_id [imsld::community_id_from_manifest_id -manifest_id $manifest_id]
            db_foreach user_in_class {
                select app.user_id
                from dotlrn_member_rels_approved app
                where app.community_id = :community_id
                and app.member_state = 'approved'
            } {
                imsld::finish_component_element -imsld_id $imsld_id \
                    -play_id $play_id \
                    -act_id $act_id \
                    -role_part_id $role_part_id \
                    -element_id $activity_id \
                    -type support \
                    -user_id $user_id \
                    -code_call
            }
        }
    }

    # 5. learning activities
    foreach referenced_la [db_list_of_lists referenced_las {
        select la.item_id as la_item_id,
        la.activity_id,
        ca.time_in_seconds
        from imsld_learning_activitiesi la,
        imsld_complete_actsi ca
        where la.complete_act_id = ca.item_id
        and content_revision__is_live(ca.complete_act_id) = 't'
        and ca.time_in_seconds is not null
    }] {
        set la_item_id [lindex $referenced_la 0]
        set activity_id [lindex $referenced_la 1]
        set time_in_seconds [lindex $referenced_la 2]
        set role_part_id [imsld::get_role_part_from_activity -activity_type learning -leaf_id $la_item_id]
        db_1row get_la_activity_info {
            select icm.manifest_id,
            ii.imsld_id,
            ip.play_id,
            ia.act_id,
            icm.creation_date
            from imsld_cp_manifestsi icm, imsld_cp_organizationsi ico, 
            imsld_imsldsi ii, imsld_methodsi im, imsld_playsi ip, 
            imsld_actsi ia, imsld_role_partsi irp
            where irp.role_part_id = :role_part_id
            and irp.act_id = ia.item_id
            and ia.play_id = ip.item_id
            and ip.method_id = im.item_id
            and im.imsld_id = ii.item_id
            and ii.organization_id = ico.item_id
            and ico.manifest_id = icm.item_id
            and content_revision__is_live(icm.manifest_id) = 't'
        }
        if { [db_0or1row compre_times {
            select 1
            where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
        }] } {
            # the act has been expired, let's mark it as finished 
            set community_id [imsld::community_id_from_manifest_id -manifest_id $manifest_id]
            db_foreach user_in_class {
                select app.user_id
                from dotlrn_member_rels_approved app
                where app.community_id = :community_id
                and app.member_state = 'approved'
            } {
                imsld::finish_component_element -imsld_id $imsld_id \
                    -play_id $play_id \
                    -act_id $act_id \
                    -role_part_id $role_part_id \
                    -element_id $activity_id \
                    -type learning \
                    -user_id $user_id \
                    -code_call
            }
        }
    }
}

ad_proc -public imsld::mark_role_part_finished { 
    -role_part_id:required
    -imsld_id:required
    -play_id:required
    -act_id:required
    {-user_id ""}
} { 
    mark the role_part as finished, as well as all the referenced activities
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { [imsld::role_part_finished_p -role_part_id $role_part_id -user_id $user_id] } {
        return
    }
    db_1row role_part_info {
        select item_id as role_part_item_id
        from imsld_role_partsi
        where role_part_id = :role_part_id
    }

    db_dml insert_role_part {
        insert into imsld_status_user (imsld_id,
                                       play_id,
                                       act_id,
                                       completed_id,
                                       user_id,
                                       type,
                                       finished_date) 
        (
         select :imsld_id,
         :play_id,
         :act_id,
         :role_part_id,
         :user_id,
         'act',
         now()
         where not exists (select 1 from imsld_status_user where imsld_id = :imsld_id and user_id = :user_id and completed_id = :role_part_id)
         )
    }

    # mark as finished all the referenced activities
    db_1row role_part_activity {
        select case
        when learning_activity_id is not null
        then 'learning'
        when support_activity_id is not null
        then 'support'
        when activity_structure_id is not null
        then 'structure'
        else 'none'
        end as type,
        content_item__get_live_revision(coalesce(learning_activity_id,support_activity_id,activity_structure_id)) as activity_id
        from imsld_role_parts
        where role_part_id = :role_part_id
    }

    if { ![string eq $type "none"] } {
        imsld::finish_component_element -imsld_id $imsld_id \
            -play_id $play_id \
            -act_id $act_id \
            -role_part_id $role_part_id \
            -element_id $activity_id \
            -type $type \
            -user_id $user_id \
            -code_call
    }
}

ad_proc -public imsld::mark_act_finished { 
    -act_id:required
    -imsld_id:required
    -play_id:required
    {-user_id ""}
} { 
    mark the act as finished, as well as all the referenced role_parts
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { [imsld::act_finished_p -act_id $act_id -user_id $user_id] } {
        return
    }
    db_1row act_info {
        select item_id as act_item_id
        from imsld_actsi
        where act_id = :act_id
    }

    db_dml insert_act {
        insert into imsld_status_user (imsld_id,
                                       play_id,
                                       completed_id,
                                       user_id,
                                       type,
                                       finished_date) 
        (
         select :imsld_id,
         :play_id,
         :act_id,
         :user_id,
         'act',
         now()
         where not exists (select 1 from imsld_status_user where imsld_id = :imsld_id and user_id = :user_id and completed_id = :act_id)
         )
    }

    foreach referenced_role_part [db_list_of_lists referenced_role_part {
        select rp.role_part_id
        from imsld_role_parts rp, imsld_actsi ia
        where rp.act_id = ia.item_id
        and ia.act_id = :act_id
        and content_revision__is_live(rp.role_part_id) = 't'
    }] {
        set role_part_id [lindex $referenced_role_part 0]
        imsld::mark_role_part_finished -role_part_id $role_part_id \
            -act_id $act_id \
            -play_id $play_id \
            -imsld_id $imsld_id \
            -user_id $user_id
    }
}

ad_proc -public imsld::mark_play_finished { 
    -play_id:required
    -imsld_id:required
    {-user_id ""}
} { 
    mark the play as finished. In this case there's only need to mark the play finished and not doing anything with the referenced acts, role_parts, etc.
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { [imsld::play_finished_p -play_id $play_id -user_id $user_id] } {
        return
    }
    db_dml insert_play {
        insert into imsld_status_user (imsld_id,
                                       completed_id,
                                       user_id,
                                       type,
                                       finished_date) 
        (
         select :imsld_id,
         :play_id,
         :user_id,
         'play',
         now()
         where not exists (select 1 from imsld_status_user where imsld_id = :imsld_id and user_id = :user_id and completed_id = :play_id)
         )
    }
    foreach referenced_act [db_list_of_lists referenced_act {
        select ia.act_id
        from imsld_acts ia, imsld_playsi ip
        where ia.play_id = ip.item_id
        and ip.play_id = :play_id
        and content_revision__is_live(ia.act_id) = 't'
    }] {
        set act_id [lindex $referenced_act 0]
        imsld::mark_act_finished -act_id $act_id \
            -play_id $play_id \
            -imsld_id $imsld_id \
            -user_id $user_id
    }
}

ad_proc -public imsld::mark_imsld_finished { 
    -imsld_id:required
    {-user_id ""}
} { 
    mark the unit of learning as finished
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { [imsld::imsld_finished_p -imsld_id $imsld_id -user_id $user_id] } {
        return
    }
    db_dml insert_uol {
        insert into imsld_status_user (imsld_id,
                                       completed_id,
                                       user_id,
                                       type,
                                       finished_date) 
        (
         select :imsld_id,
         :imsld_id,
         :user_id,
         'play',
         now()
         where not exists (select 1 from imsld_status_user where imsld_id = :imsld_id and user_id = :user_id and completed_id = :imsld_id)
         )
    }

    foreach referenced_play [db_list_of_lists referenced_plays {
        select ip.play_id
        from imsld_plays ip, imsld_methodsi im, imsld_imsldsi ii
        where ip.method_id = im.item_id
        and im.imsld_id = ii.item_id
        and ii.imsld_id = :imsld_id
    }] {
        set play_id [lindex $referenced_play 0]
        imsld::mark_play_finished -play_id $play_id \
            -imsld_id $imsld_id \
            -user_id $user_id
    }
}

ad_proc -public imsld::mark_method_finished { 
    -imsld_id:required
    -method_id:required
    {-user_id ""}
} { 
    mark the method as finished
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { [imsld::method_finished_p -method_id $method_id -user_id $user_id] } {
        return
    }
    db_dml insert_method {
        insert into imsld_status_user (imsld_id,
                                       completed_id,
                                       user_id,
                                       type,
                                       finished_date) 
        (
         select :imsld_id,
         :method_id,
         :user_id,
         'method',
         now()
         where not exists (select 1 from imsld_status_user where imsld_id = :imsld_id and user_id = :user_id and completed_id = :method_id)
         )
    }

    foreach referenced_play [db_list_of_lists referenced_plays {
        select ip.play_id
        from imsld_plays ip, imsld_methodsi im
        where ip.method_id = im.item_id
        and im.method_id = :method_id
    }] {
        set play_id [lindex $referenced_play 0]
        imsld::mark_play_finished -play_id $play_id \
            -imsld_id $imsld_id \
            -user_id $user_id
    }
}

ad_proc -public imsld::rel_type_delete { 
    -rel_type:required
} { 
    Deletes a rel type (since the rel_types does not have a delete proc)
} {  

    db_1row select_type_info {
        select t.table_name 
        from acs_object_types t
        where t.object_type = :rel_type
    }
    
    set rel_id_list [db_list select_rel_ids {
        select r.rel_id
        from acs_rels r
        where r.rel_type = :rel_type
    }]
    
    # delete all relations and drop the relationship
    # type. 
    
    db_transaction {
        foreach rel_id $rel_id_list {
            relation_remove $rel_id
        }
        
        db_exec_plsql drop_relationship_type {
            BEGIN
            acs_rel_type.drop_type( rel_type  => :rel_type,
                                    cascade_p => 't' );
            END;
        }
    } on_error {
        ad_return_error "Error deleting relationship type" "We got the following error trying to delete this relationship type:<pre>$errmsg</pre>"
        ad_script_abort
    }
    # If we successfully dropped the relationship type, drop the table.
    # Note that we do this outside the transaction as it commits all
    # transactions anyway
    if { [db_table_exists $table_name] } {
        db_exec_plsql drop_type_table "drop table $table_name"
    }
} 

ad_proc -public imsld::item_revision_new {
    {-attributes ""}
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -content_type
    -edit:boolean
    -parent_id
} {
    Creates a new revision of a content item, calling the cr functions. 
    If editing, only a new revision is created, otherwise an item is created too.

    @option attributes A list of lists of pairs of additional attributes and their values.
    @option title 
    @option package_id 
    @option user_id 
    @option creation_ip 
    @option creation_date 
    @option edit Are we editing the manifest?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [string eq "" $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [string eq "" $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [string eq "" $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [string eq "" $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set item_name "${item_id}_content_type"
    set title [expr { [string eq "" $title] ? $item_name : $title }]
    
    if { !$edit_p } {
        # create
        set item_id [content::item::new -item_id $item_id \
                         -name $item_name \
                         -content_type $content_type \
                         -parent_id $parent_id \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -context_id $package_id]
    }
    
    if { ![string eq "" $attributes] } {
        set revision_id [content::revision::new -item_id $item_id \
                             -title $title \
                             -content_type $content_type \
                             -creation_user $user_id \
                             -creation_ip $creation_ip \
                             -item_id $item_id \
                             -is_live "t" \
                             -attributes $attributes]
    } else {
        set revision_id [content::revision::new -item_id $item_id \
                             -title $title \
                             -content_type $content_type \
                             -creation_user $user_id \
                             -creation_ip $creation_ip \
                             -item_id $item_id \
                             -is_live "t"]
    }
    
    return $item_id
}

ad_proc -public imsld::finish_component_element {
    -imsld_id
    {-play_id ""}
    {-act_id ""}
    {-role_part_id ""}
    -element_id
    -type
    -code_call:boolean
    {-user_id ""}
} {
    @option imsld_id
    @option play_id
    @option act_id
    @option role_part_id
    @option element_id
    @option type
    @option code_call
    @option user_id

    Mark as finished the given component_id. This is done by adding a row in the table insert_entry.

    This function is called from a url, but it can also be called recursively
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { !$code_call_p } {
        # get the url for parse it and get the info
        set url [ns_conn url]
        regexp {finish-component-element-([0-9]+)-([0-9]+)-([0-9]+)-([a-z]+).imsld$} $url match imsld_id role_part_id element_id type
        regsub {/finish-component-element.*} $url "" return_url 
    }
    # now that we have the necessary info, mark the finished element completed and return
    db_dml insert_element_entry {
        insert into imsld_status_user (
                                       select :imsld_id,
                                       :play_id,
                                       :act_id,
                                       :role_part_id,
                                       :element_id,
                                       :user_id,
                                       :type,
                                       now()
                                       where not exists (select 1 from imsld_status_user where imsld_id = :imsld_id and user_id = :user_id and completed_id = :element_id)
                                       )
    }

    if { [string eq $type "learning"] || [string eq $type "support"] || [string eq $type "structure"] } {
        foreach referencer_structure_list [db_list_of_lists referencer_structure {
            select ias.structure_id,
            ias.item_id as structure_item_id
            from acs_rels ar, imsld_activity_structuresi ias, cr_items cri
            where ar.object_id_one = ias.item_id
            and ar.object_id_two = cri.item_id
            and cri.live_revision = :element_id
        }] {
            set structure_id [lindex $referencer_structure_list 0]
            set structure_item_id [lindex $referencer_structure_list 1]
            # if this activity is part of an activity structure, let's check if the rest of referenced 
            # activities are finished too, so we can mark finished the activity structure as well
            set scturcture_finished_p 1
            db_foreach referenced_activity {
                select content_item__get_live_revision(ar.object_id_two) as activity_id
                from acs_rels ar
                where ar.object_id_one = :structure_item_id
                and ar.rel_type in ('imsld_as_la_rel','imsld_as_sa_rel','imsld_as_as_rel')
            } {
                if { ![db_string completed_p {
                    select count(*) from imsld_status_user 
                    where completed_id = :activity_id
                    and user_id = :user_id
                }] } {
                    # there is at leas one no-completed activity, so we can't mark this activity structure yet
                    set scturcture_finished_p 0
                }
            }
            if { $scturcture_finished_p } {
                imsld::finish_component_element -imsld_id $imsld_id \
                    -role_part_id $role_part_id \
                    -element_id $structure_id \
                    -type structure \
                    -user_id $user_id \
                    -code_call
            }
        }
    }

    # we continue with A LOT of validations (in order to support the when-xxx-finished tag of the spec 
    # -- with xxx in (role_part,act,play)):
    # 1. let's see if the finished activity triggers the ending of the role_part
    # 2. let's see if the finished role_part triggers the ending of the act which references it.
    # 3. let's see if the finished act triggers the ending the play which references it
    # 4. let's see if the finished play triggers the ending of the method which references it.
    if { [imsld::role_part_finished_p -role_part_id $role_part_id -user_id $user_id] && ![db_0or1row already_marked_p {select 1 from imsld_status_user where completed_id = :role_part_id and user_id = :user_id}] } { 
        # case number 1
        imsld::finish_component_element -imsld_id $imsld_id \
            -play_id $play_id \
            -act_id $act_id \
            -role_part_id $role_part_id \
            -element_id $role_part_id \
            -type role-part \
            -user_id $user_id \
            -code_call

        db_1row get_role_part_info {
            select ii.imsld_id,
            ip.play_id,
            ip.item_id as play_item_id,
            ia.act_id,
            ia.item_id as act_item_id,
            ica.when_last_act_completed_p,
            im.method_id,
            im.item_id as method_item_id
            from imsld_imsldsi ii, imsld_actsi ia, imsld_role_parts irp, 
               imsld_methodsi im, imsld_playsi ip left outer join imsld_complete_actsi ica on (ip.complete_act_id = ica.item_id)
            where irp.role_part_id = :role_part_id
            and irp.act_id = ia.item_id
            and ia.play_id = ip.item_id
            and ip.method_id = im.item_id
            and im.imsld_id = ii.item_id
            and content_revision__is_live(ii.imsld_id) = 't';
        }

        set completed_act_p 1 
        set rel_defined_p 0
        db_foreach referenced_role_part {
            select ar.object_id_two as role_part_item_id,
            rp.role_part_id
            from acs_rels ar, imsld_role_partsi rp
            where ar.object_id_one = :act_item_id
            and rp.item_id = ar.object_id_two
            and ar.rel_type = 'imsld_act_rp_completed_rel'
            and content_revision__is_live(rp.role_part_id) = 't'
        } {
            if { ![imsld::role_part_finished_p -role_part_id $role_part_id -user_id $user_id] } {
                set completed_act_p 0
            }
        } if_no_rows {
            # the act doesn't have any imsld_act_rp_completed_rel rel defined.
            set rel_defined_p 1
        }
        if { $rel_defined_p } {
            # check if all the role parts have been finished and mar the act as finished.
            db_foreach directly_referenced_role_part {
                select irp.role_part_id
                from imsld_role_parts irp
                where irp.act_id = :act_item_id
                and content_revision__is_live(irp.role_part_id) = 't'
            } {
                if { ![imsld::role_part_finished_p -role_part_id $role_part_id -user_id $user_id] } {
                    set completed_act_p 0
                }
            }
        }

        if { $completed_act_p } {
            # case number 2
            imsld::mark_act_finished -act_id $act_id \
                -play_id $play_id \
                -imsld_id $imsld_id \
                -user_id $user_id
            
            set completed_play_p 1
            db_foreach referenced_act {
                select ia.act_id
                from imsld_acts ia, imsld_playsi ip
                where ia.play_id = :play_item_id
                and ip.item_id = ia.play_id
                and content_revision__is_live(ia.act_id) = 't'
            } {
                if { ![imsld::act_finished_p -act_id $act_id -user_id $user_id] } {
                    set completed_play_p 0
                }
            }
            if { $completed_play_p } {
                # case number 3
                imsld::mark_play_finished -play_id $play_id \
                    -imsld_id $imsld_id \
                    -user_id $user_id 
                
                set completed_unit_of_learning_p 1 
                set rel_defined_p 0
                db_foreach referenced_play {
                    select ip.play_id
                    from acs_rels ar, imsld_playsi ip
                    where ar.object_id_one = :method_item_id
                    and ip.item_id = ar.object_id_two
                    and ar.rel_type = 'imsld_mp_completed_rel'
                    and content_revision__is_live(ip.play_id) = 't'
                } {
                    if { ![imsld::play_finished_p -play_id $play_id -user_id $user_id] } {
                        set completed_unit_of_learning_p 0
                    }
                } if_no_rows {
                    # the uol doesn't have any imsld_mp_completed_rel rel defined.
                    set rel_defined_p 1
                }
                if { $rel_defined_p } {
                    # check if all the plays have been finished and mark the imsld as finished.
                    db_foreach directly_referenced_plays {
                        select ip.play_id
                        from imsld_plays ip
                        where ip.method_id = :method_item_id
                        and content_revision__is_live(ip.play_id) = 't'
                    } {
                        if { ![imsld::play_finished_p -play_id $play_id -user_id $user_id] } {
                            set completed_unit_of_learning_p 0
                        }
                    }
                }
                        
                if { $completed_unit_of_learning_p } {
                    # case number 4
                    imsld::mark_imsld_finished -imsld_id $imsld_id -user_id $user_id
                }
            }
        }
    }
    if { !$code_call_p } {
        ad_returnredirect "${return_url}"
    }
} 

ad_proc -public imsld::structure_next_activity {
    -activity_structure_id:required
    {-environment_list ""}
} { 
    @return The next learning or support activity (and the type) in the activity structure. 0 if there are none (which should never happen)
} {
    set user_id [ad_conn user_id]
    set min_sort_order ""
    set next_activity_id ""
    set next_activity_type ""
    # get referenced activities
    foreach referenced_activity [db_list_of_lists struct_referenced_activities {
        select ar.object_id_two,
        ar.rel_type
        from acs_rels ar, imsld_activity_structuresi ias
        where ar.object_id_one = ias.item_id
        and ias.structure_id = :activity_structure_id
        order by ar.object_id_two
    }] {
        set object_id_two [lindex $referenced_activity 0]
        set rel_type [lindex $referenced_activity 1]
        switch $rel_type {
            imsld_as_la_rel {
                # find out if is the next one
                db_1row get_la_info {
                    select sort_order, 
                    activity_id as learning_activity_id
                    from imsld_learning_activitiesi
                    where item_id = :object_id_two
                    and content_revision__is_live(activity_id) = 't'
                }
                if { ![db_string completed_p_from_la {
                    select count(*)
                    from imsld_status_user
                    where completed_id = :learning_activity_id
                    and user_id = :user_id
                }] && ( [string eq "" $min_sort_order] || $sort_order < $min_sort_order ) } {
                    set min_sort_order $sort_order
                    set next_activity_id $learning_activity_id
                    set next_activity_type learning
                }
            }
            imsld_as_sa_rel {
                # find out if is the next one
                db_1row get_sa_info {
                    select sort_order, 
                    activity_id as support_activity_id
                    from imsld_support_activitiesi
                    where item_id = :object_id_two
                    and content_revision__is_live(activity_id) = 't'
                }
                if { ![db_string completed_p_from_sa {
                    select count(*)
                    from imsld_status_user
                    where completed_id = :support_activity_id
                    and user_id = :user_id
                }] && ( [string eq "" $min_sort_order] || $sort_order < $min_sort_order ) } {
                    set min_sort_order $sort_order
                    set next_activity_id $support_activity_id
                    set next_activity_type support
                }
            }
            imsld_as_as_rel {
                # recursive call?

                db_1row get_as_info {
                    select sort_order, structure_id, item_id
                    from imsld_activity_structuresi
                    where item_id = :object_id_two
                    and content_revision__is_live(structure_id) = 't'
                }

                if { ![db_string completed_p { 
                    select count(*)
                    from imsld_status_user 
                    where completed_id = :structure_id
                    and user_id = :user_id
                }] && ( [string eq "" $min_sort_order] || $sort_order < $min_sort_order ) } {
                    set min_sort_order $sort_order
                    set activity_id $structure_id
                    set next_activity_type structure
                }
            }
            imsld_as_env_rel {
                if { [llength $environment_list] } {
                    set environment_list [concat [list $environment_list] [list [imsld::process_environment -environment_item_id $object_id_two]]]
                } else {
                    set environment_list [imsld::process_environment -environment_item_id $object_id_two]
                }
            }
        }
    } 

    if { [string eq $next_activity_type structure] } {
        set next_activity_list [imsld::structure_next_activity -activity_structure_id $activity_id -environment_list $environment_list]
        set next_activity_id [lindex $next_activity_list 0]
        set next_activity_type [lindex $next_activity_list 1]
        set environment_list [concat $environment_list [lindex $next_activity_list 2]]
    }
    return [list $next_activity_id $next_activity_type $environment_list]
} 

ad_proc -public imsld::role_part_finished_p { 
    -role_part_id:required
    {-user_id ""}
} { 
    @param role_part_id Role Part identifier
    
    @return 0 if the role part hasn't been finished. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { [db_0or1row already_marked_p {
        select 1 
        from imsld_status_user
        where completed_id = :role_part_id
        and user_id = :user_id
    }] } {
        # simple case, already marked as finished
        return 1
    }

    db_1row get_role_part_activity {
        select case
        when learning_activity_id is not null
        then 'learning'
        when support_activity_id is not null
        then 'support'
        when activity_structure_id is not null
        then 'structure'
        else 'none'
        end as type,
        learning_activity_id,
        support_activity_id,
        activity_structure_id
        from imsld_role_parts
        where role_part_id = :role_part_id
    }
    switch $type {
        learning {
            if { [db_string completed_from_la {
                select count(*) from imsld_status_user
                where completed_id = content_item__get_live_revision(:learning_activity_id)
                and user_id = :user_id
            }] } {
                return 1
            }
        }
        support {
            if { [db_string completed_from_sa {
                select count(*) from imsld_status_user
                where completed_id = content_item__get_live_revision(:support_activity_id)
                and user_id = :user_id
            }] } {
                return 1
            }
        }
        structure {
            if { [db_string completed_from_as {
                select count(*) from imsld_status_user
                where completed_id = content_item__get_live_revision(:activity_structure_id)
                and user_id = :user_id
            }] } {
                return 1
            }
        }
        none {
            return 1
        }
    }
    return 0
} 

ad_proc -public imsld::act_finished_p { 
    -act_id:required
    {-user_id ""}
} { 
    @param act_id
    
    @return 0 if the at hasn't been finished. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    return [db_0or1row already_marked_p {
        select 1 
        from imsld_status_user
        where completed_id = :act_id
        and user_id = :user_id
    }]
} 

ad_proc -public imsld::play_finished_p { 
    -play_id:required
    {-user_id ""}
} { 
    @param play_id
    
    @return 0 if the play hasn't been finished. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    return [db_0or1row play_marked_p {
        select 1 
        from imsld_status_user
        where completed_id = :play_id
        and user_id = :user_id
    }]
} 

ad_proc -public imsld::method_finished_p { 
    -method_id:required
    {-user_id ""}
} { 
    @param method_id
    
    @return 0 if the method hasn't been finished. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    return [db_0or1row method_marked_p {
        select 1 
        from imsld_status_user
        where completed_id = :method_id
        and user_id = :user_id
    }]
} 

ad_proc -public imsld::imsld_finished_p { 
    -imsld_id:required
    {-user_id ""}
} { 
    @param imsld_id
    
    @return 0 if the imsld hasn't been finished. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    return [db_0or1row imsld_marked_p {
        select 1 
        from imsld_status_user
        where completed_id = :imsld_id
        and user_id = :user_id
    }]
} 

ad_proc -public imsld::process_service {
    -service_item_id:required
    {-resource_mode "f"}
} { 
    returns a list of the associated resources referenced from the given service.
} {
    set services_list [list]

    # get service info
    db_1row service_info {
        select serv.service_id,
        serv.identifier,
        serv.class,
        serv.is_visible_p,
        serv.service_type
        from imsld_servicesi serv 
        where serv.item_id = :service_item_id
        and content_revision__is_live(serv.service_id) = 't'
    }

    switch $service_type {
        conference {
            db_1row get_conference_info {
                select conf.conference_id,
                conf.conference_type,
                conf.imsld_item_id as imsld_item_item_id,
                cr.live_revision as imsld_item_id
                from imsld_conference_services conf, cr_items cr
                where conf.service_id = :service_item_id
                and cr.item_id = conf.imsld_item_id
                and content_revision__is_live(cr.live_revision) = 't'
            }
            db_foreach serv_associated_items {
                select cpr.resource_id,
                cpr.item_id as resource_item_id,
                cpr.type as resource_type
                from imsld_cp_resourcesi cpr, imsld_itemsi ii,
                acs_rels ar
                where ar.object_id_one = ii.item_id
                and ar.object_id_two = cpr.item_id
                and content_revision__is_live(cpr.resource_id) = 't'
                and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                     and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                     or ii.imsld_item_id = :imsld_item_id)
            } {
                if {[string eq "t" $resource_mode]} {
                    lappend resource_item_list $resource_item_id
                }
                append one_service_url "[imsld::process_resource -resource_item_id $resource_item_id]"
                if { [string eq "" $one_service_url] } {
                    lappend services_list "[_ imsld.lt_li_desc_no_file_assoc]"
                } else {
                    set services_list [expr { [llength $services_list] ? [concat [list $services_list] [list $one_service_url]] : $one_service_url }]
                }
            } if_no_rows {
                ns_log notice "[_ imsld.lt_li_desc_no_file_assoc]"
            }
        }
        default {
            return "not_implemented_yet ($service_type)"
        }
    }
    if {[string eq "t" $resource_mode]} {
        return [list $services_list $resource_item_list]
    } else {
        return "$services_list"       
    }

}

ad_proc -public imsld::process_environment {
    -environment_item_id:required
    {-community_id ""}
    {-resource_mode "f"}
} { 
    returns a list of the associated resources, files and environments referenced from the given environment.
} {  
    set community_id [expr { [string eq "" $community_id] ? "[dotlrn_community::get_community_id]" : $community_id }]
    set fs_package_id [site_node_apm_integration::get_child_package_id \
                           -package_id [dotlrn_community::get_package_id $community_id] \
                           -package_key "file-storage"]
    
    set root_folder_id [fs::get_root_folder -package_id $fs_package_id]

    # get environment info
    db_1row environment_info {
        select env.title as environment_title,
        env.environment_id
        from imsld_environmentsi env
        where env.item_id = :environment_item_id
        and content_revision__is_live(env.environment_id) = 't'
    }

    set environment_learning_objects_list [list]
    if { [db_0or1row get_learning_object_info {
        select item_id as learning_object_item_id,
        learning_object_id,
        identifier
        from imsld_learning_objectsi
        where environment_id = :environment_item_id
        and content_revision__is_live(learning_object_id) = 't'
    }] } {
        # learning object item. get the files associated
        set linear_item_list [db_list item_linear_list {
            select ii.imsld_item_id
            from imsld_items ii,
            cr_items cr,
            acs_rels ar
            where ar.object_id_one = :learning_object_item_id
            and ar.object_id_two = cr.item_id
            and cr.live_revision = ii.imsld_item_id
        }]
        foreach imsld_item_id $linear_item_list {
            db_foreach env_nested_associated_items {
                select cpr.resource_id,
                cpr.item_id as resource_item_id,
                cpr.type as resource_type
                from imsld_cp_resourcesi cpr, imsld_itemsi ii,
                acs_rels ar
                where ar.object_id_one = ii.item_id
                and ar.object_id_two = cpr.item_id
                and content_revision__is_live(cpr.resource_id) = 't'
                and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                     and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                     or ii.imsld_item_id = :imsld_item_id)
            } { 
                if { [string eq "t" $resource_mode] } {
                    lappend resource_item_list $resource_item_id
                }
                set one_learning_object_list [imsld::process_resource -resource_item_id $resource_item_id]
                if { [string eq "" $one_learning_object_list] } {
                    lappend environment_learning_objects_list "[_ imsld.lt_li_desc_no_file_assoc]"
                } else {
                    if { [string eq "t" $resource_mode] } { 
                     set environment_learning_objects_list [concat [list $environment_learning_objects_list] \
                                                               [list $one_learning_object_list] \
                                                               $resource_item_list ]
                    } else { 
                      set environment_learning_objects_list [concat [list $environment_learning_objects_list] \
                                                               [list $one_learning_object_list] ]
                    }
                }
            } if_no_rows {
                ns_log notice "[_ imsld.lt_li_desc_no_file_assoc]"
            }
        }
    }
    # services
    set environment_services_list [list]
    if { [db_0or1row get_service_info {
        select service_id,
        item_id as service_item_id,
        identifier,
        service_type
        from imsld_servicesi
        where environment_id = :environment_item_id
        and content_revision__is_live(service_id) = 't'
    }] } {
        set environment_services_list [imsld::process_service -service_item_id $service_item_id -resource_mode $resource_mode]
    }

    set nested_environment_list [list]
    # environments
    db_foreach nested_environment {
        select ar.object_id_two as nested_environment_item_id
        from acs_rels ar
        where ar.object_id_one = :environment_item_id
        and ar.rel_type = 'imsld_env_env_rel'
    } {
        set one_nested_environment_list [imsld::process_environment -environment_item_id $nested_environment_item_id]
        # the title is stored in [lindex $one_nested_environment_list 0], but is not returned for displaying porpouses
        set nested_environment_list [concat [list $nested_environment_list] \
                                         [list [lindex $one_nested_environment_list 1] \
                                              [lindex $one_nested_environment_list 2] \
                                              [lindex $one_nested_environment_list 3]]]
    }
    return [list $environment_title $environment_learning_objects_list $environment_services_list $nested_environment_list]
}

ad_proc -public imsld::process_learning_objective {
    {-imsld_item_id ""}
    {-activity_item_id ""}
    {-community_id ""}
    {-resource_mode "f"}
} {
    returns a list with the objective title and the associated resources, files and environments referenced from the learning objective of the given activity or ims-ld
} {  
    set community_id [expr { [string eq "" $community_id] ? "[dotlrn_community::get_community_id]" : $community_id }]
    # Gets file-storage root folder_id
    set fs_package_id [site_node_apm_integration::get_child_package_id \
                           -package_id [dotlrn_community::get_package_id $community_id] \
                           -package_key "file-storage"]
    set root_folder_id [fs::get_root_folder -package_id $fs_package_id]
    
    set learning_objective_item_id ""
    if { ![string eq "" $imsld_item_id] } {
        db_0or1row get_lo_id_from_iii { 
            select learning_objective_id as learning_objective_item_id
            from imsld_imsldsi
            where item_id = :imsld_item_id
            and content_revision__is_live(imsld_id) = 't'
        }
    } elseif { ![string eq "" $activity_item_id] } {
        db_0or1row get_lo_id_from_aii { 
            select learning_objective_id as learning_objective_item_id
            from imsld_learning_activitiesi
            where item_id = :activity_item_id
            and content_revision__is_live(activity_id) = 't'
        }
    } else {
        return -code error "IMSLD::imsld::process_learning_objective: Invalid call"
    }

    if { [string eq "" $learning_objective_item_id] } {
        return ""
    }

    # get learning object info
    db_1row objective_info {
        select coalesce(lo.pretty_title, '') as objective_title,
        lo.learning_objective_id
        from imsld_learning_objectivesi lo
        where lo.item_id = :learning_objective_item_id
        and content_revision__is_live(lo.learning_objective_id) = 't'
    }
    set objective_items_list [list]

    # get the items associated with the learning objective
    set linear_item_list [db_list item_linear_list {
        select ii.imsld_item_id
        from imsld_items ii,
        cr_items cr, acs_rels ar
        where ar.object_id_one = :learning_objective_item_id
        and ar.object_id_two = cr.item_id
        and cr.live_revision = ii.imsld_item_id
    }]
    foreach imsld_item_id $linear_item_list {
        db_foreach lo_nested_associated_items {
            select cpr.resource_id,
            cpr.item_id as resource_item_id,
            cpr.type as resource_type
            from imsld_cp_resourcesi cpr, imsld_itemsi ii,
            acs_rels ar
            where ar.object_id_one = ii.item_id
            and ar.object_id_two = cpr.item_id
            and content_revision__is_live(cpr.resource_id) = 't'
            and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 or ii.imsld_item_id = :imsld_item_id)
        } {
            if { [string eq "t" $resource_mode] } {
                lappend resource_item_list $resource_item_id
            }
            set one_objective_urls "[imsld::process_resource -resource_item_id $resource_item_id]"
            if { [string eq "" $one_objective_urls] } {
                lappend objective_items_list "[_ imsld.lt_li_desc_no_file_assoc]"
            } else {
                set objective_items_list [concat [list $objective_items_list] [list $one_objective_urls]]
            }
        } if_no_rows {
            ns_log notice "[_ imsld.lt_li_desc_no_file_assoc]"
        }
    }
    if { [string eq "t" $resource_mode] } {
        return [list $objective_title $objective_items_list $resource_item_list]
    } else {
        return [list $objective_title $objective_items_list]
    }


}

ad_proc -public imsld::process_prerequisite {
    {-imsld_item_id ""}
    {-activity_item_id ""}
    {-community_id ""}
    {-resource_mode "f"}
} {
    returns a list of the associated resources, files and environments referenced from the prerequisite of the given ims-ld or activity
} {  
    set community_id [expr { [string eq "" $community_id] ? "[dotlrn_community::get_community_id]" : $community_id }]
    # Gets file-storage root folder_id
    set fs_package_id [site_node_apm_integration::get_child_package_id \
                           -package_id [dotlrn_community::get_package_id $community_id] \
                           -package_key "file-storage"]
    set root_folder_id [fs::get_root_folder -package_id $fs_package_id]
    
    set prerequisite_item_id ""
    if { ![string eq "" $imsld_item_id] } {
        db_0or1row get_lo_id_from_iii { 
            select prerequisite_id as prerequisite_item_id
            from imsld_imsldsi
            where item_id = :imsld_item_id
            and content_revision__is_live(imsld_id) = 't'
        }
    } elseif { ![string eq "" $activity_item_id] } {
        db_0or1row get_lo_id_from_aii { 
            select prerequisite_id as prerequisite_item_id
            from imsld_learning_activitiesi
            where item_id = :activity_item_id
            and content_revision__is_live(activity_id) = 't'
        }
    } else {
        return -code error "IMSLD::imsld::process_prerequisite: Invalid call"
    }

    if { [string eq "" $prerequisite_item_id] } {
        return ""
    }

    # get prerequisite info
    db_1row prerequisite_info {
        select coalesce(pre.pretty_title, '') as prerequisite_title,
        pre.prerequisite_id
        from imsld_prerequisitesi pre
        where pre.item_id = :prerequisite_item_id
        and content_revision__is_live(pre.prerequisite_id) = 't'
    }

    set prerequisite_items_list [list]

    # get the items associated with the learning objective
    set linear_item_list [db_list item_linear_list {
        select ii.imsld_item_id
        from imsld_items ii,
        cr_items cr, acs_rels ar
        where ar.object_id_one = :prerequisite_item_id
        and ar.object_id_two = cr.item_id
        and cr.live_revision = ii.imsld_item_id
    }]
    foreach imsld_item_id $linear_item_list {
        db_foreach prereq_nested_associated_items {
            select cpr.resource_id,
            cpr.item_id as resource_item_id,
            cpr.type as resource_type
            from imsld_cp_resourcesi cpr, imsld_itemsi ii,
            acs_rels ar
            where ar.object_id_one = ii.item_id
            and ar.object_id_two = cpr.item_id
            and content_revision__is_live(cpr.resource_id) = 't'
            and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 or ii.imsld_item_id = :imsld_item_id)
        } { 
            if { [string eq "t" $resource_mode] } { 
                lappend resource_item_list $resource_item_id
            }
            set one_prerequisite_urls "[imsld::process_resource -resource_item_id $resource_item_id]"
            if { [string eq "" $one_prerequisite_urls] } {
                lappend prerequisite_items_list "[_ imsld.lt_li_desc_no_file_assoc]"
            } else {
                set prerequisite_items_list [concat [list $prerequisite_items_list] [list $one_prerequisite_urls] ]
            }
        } if_no_rows {
            ns_log notice "[_ imsld.lt_li_desc_no_file_assoc]"
        }
    }
    if { [string eq "t" $resource_mode] } {
        return [list $prerequisite_title $prerequisite_items_list $resource_item_list]
    } else {
        return [list $prerequisite_title $prerequisite_items_list]
    }

}

ad_proc -public imsld::process_feedback {
    {-on_completion_item_id ""}
    {-community_id ""}
} {
    returns a list with the feedback title and the associated resources, files and environments referenced from the on_completion element.
} {  
    set community_id [expr { [string eq "" $community_id] ? "[dotlrn_community::get_community_id]" : $community_id }]
    # Gets file-storage root folder_id
    set fs_package_id [site_node_apm_integration::get_child_package_id \
                           -package_id [dotlrn_community::get_package_id $community_id] \
                           -package_key "file-storage"]
    set root_folder_id [fs::get_root_folder -package_id $fs_package_id]
    
    set feedback_item_id ""

    # get on completion info
    db_1row feedback_info {
        select coalesce(oc.feedback_title, oc.title) as feedback_title
        from imsld_on_completioni oc
        where oc.item_id = :on_completion_item_id
        and content_revision__is_live(oc.on_completion_id) = 't'
    }

    set feedback_items_list [list]
    # get the items associated with the feedback
    set linear_item_list [db_list item_linear_list {
        select ii.imsld_item_id
        from imsld_items ii,
        cr_items cr, acs_rels ar
        where ar.object_id_one = :on_completion_item_id
        and ar.object_id_two = cr.item_id
        and cr.live_revision = ii.imsld_item_id
    }]
    foreach imsld_item_id $linear_item_list {
        db_foreach feedback_nested_associated_items {
            select cpr.resource_id,
            cpr.item_id as resource_item_id,
            cpr.type as resource_type
            from imsld_cp_resourcesi cpr, imsld_itemsi ii,
            acs_rels ar
            where ar.object_id_one = ii.item_id
            and ar.object_id_two = cpr.item_id
            and content_revision__is_live(cpr.resource_id) = 't'
            and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 or ii.imsld_item_id = :imsld_item_id)
        } {
            set one_feedback_urls [imsld::process_resource -resource_item_id $resource_item_id]
            if { [string eq "" $one_feedback_urls] } {
                lappend feedback_items_list "[_ imsld.lt_li_desc_no_file_assoc]"
            } else {
                set feedback_items_list [concat [list $feedback_items_list] [list $one_feedback_urls]]
            }
        }
    }
    return [list $feedback_title $feedback_items_list]
}

ad_proc -public imsld::process_resource { 
    -resource_item_id
    {-community_id ""}
} {
    @param resource_item_id

    @return The list (li) of files associated to the given resource_id
} {
    set community_id [expr { [string eq "" $community_id] ? "[dotlrn_community::get_community_id]" : $community_id }]
    db_1row get_resource_info {
        select identifier,
        type as resource_type,
        title as resource_title,
        acs_object_id
        from imsld_cp_resourcesi 
        where item_id = :resource_item_id 
        and content_revision__is_live(resource_id) = 't'
    }
    set files_urls ""
    if { ![string eq $resource_type "webcontent"] && ![string eq $acs_object_id ""] } {
        if { [db_0or1row is_cr_item {
            select live_revision from cr_items where item_id = :acs_object_id
        }] } {
            db_1row get_cr_info { 
                select acs_object__name(object_id) as object_title, object_type
                from acs_objects where object_id = :live_revision
            } 
        } else {
            db_1row get_ao_info { 
                select acs_object__name(object_id) as object_title, object_type
                from acs_objects where object_id = :acs_object_id
            } 
        }
        set file_url [acs_sc::invoke -contract FtsContentProvider -operation url -impl $object_type -call_args [list $acs_object_id]]
        set image_path [imsld::object_type_image_path -object_type $object_type]
        append files_urls "<a href=[export_vars -base imsld/imsld-finish-resource {file_url $file_url resource_item_id $resource_item_id}] target=\"_blank\"><img src=\"$image_path\" border=0 alt=\"$object_title\"></a> "
    } else {
        # Get file-storage root folder_id
        set fs_package_id [site_node_apm_integration::get_child_package_id \
                               -package_id [dotlrn_community::get_package_id $community_id] \
                               -package_key "file-storage"]
        set root_folder_id [fs::get_root_folder -package_id $fs_package_id]
        # get associated files
        db_foreach associated_files {
            select cpf.imsld_file_id,
            cpf.file_name,
            cpf.item_id, cpf.parent_id
            from imsld_cp_filesx cpf,
            acs_rels ar
            where ar.object_id_one = :resource_item_id
            and ar.object_id_two = cpf.item_id
            and content_revision__is_live(cpf.imsld_file_id) = 't'
        } {
            # get the fs file path
            set folder_path [db_exec_plsql get_folder_path { select content_item__get_path(:parent_id,:root_folder_id); }]
            set fs_file_url [db_1row get_fs_file_url {
                select 
                case 
                when :folder_path is null
                then fs.file_upload_name
                else :folder_path || '/' || fs.file_upload_name
                end as file_url
                from fs_objects fs
                where fs.live_revision = :imsld_file_id

            }]
            set file_url "[apm_package_url_from_id $fs_package_id]view/${file_url}"
            append files_urls "<a href=[export_vars -base imsld/imsld-finish-resource {file_url $file_url resource_item_id $resource_item_id}] target=\"_blank\"><img src=\"[lindex [site_node::get_url_from_object_id -object_id [ad_conn package_id]] 0][imsld::package_key]/resources/file-storage.png\" alt=\"$file_name\" border=0></a> "

        }
        # get associated urls
        db_foreach associated_urls {
            select url
            from acs_rels ar,
            cr_extlinks links
            where ar.object_id_one = :resource_item_id
            and ar.object_id_two = links.extlink_id
        } {
            append files_urls "<a href=[export_vars -base $url] target=\"_blank\"><img src=\"[lindex [site_node::get_url_from_object_id -object_id [ad_conn package_id]] 0][imsld::package_key]/resources/url.png\" border=0  alt=\"$url\"></a> "
        }
    }
    return $files_urls
}

ad_proc -public imsld::process_learning_activity { 
    -activity_item_id:required
    {-community_id ""}
    {-resource_mode "f"}
} {
    @param 
    @option user_id default [ad_conn user_id]
    
    @return The list (activity_name, list of associated urls) of the next activity for the user in the IMS-LD.
} {
    db_1row activity_info {
        select on_completion_id as on_completion_item_id,
        prerequisite_id as prerequisite_item_id,
        learning_objective_id as learning_objective_item_id,
        activity_id
        from imsld_learning_activitiesi
        where item_id = :activity_item_id
        and content_revision__is_live(activity_id) = 't'
    }

    # get environments
    set environments_list [list]
    set associated_environments_list [db_list la_associated_environments {
        select ar.object_id_two as environment_item_id
        from acs_rels ar
        where ar.object_id_one = :activity_item_id
        and ar.rel_type = 'imsld_la_env_rel'
        order by ar.object_id_two
    }]
    foreach environment_item_id $associated_environments_list {
        if { [llength $environments_list] } {
            set environments_list [concat [list $environments_list] \
                                       [list [imsld::process_environment -environment_item_id $environment_item_id -resource_mode $resource_mode]]]
        } else {
            set environments_list [imsld::process_environment -environment_item_id $environment_item_id -resource_mode $resource_mode]
        }
    }

    # prerequisites
    set prerequisites_list [list]
    if { ![string eq "" $prerequisite_item_id] } {
        set prerequisites_list [imsld::process_prerequisite -activity_item_id $activity_item_id -resource_mode $resource_mode]
    }
    # learning objectives
    set objectives_list [list]
    if { ![string eq "" $learning_objective_item_id] } {
        set objectives_list [imsld::process_learning_objective -activity_item_id $activity_item_id -resource_mode $resource_mode]
    }

    set activity_items_list [list]
    # get the items associated with the activity
    set linear_item_list [db_list item_linear_list {
        select ii.imsld_item_id
        from imsld_items ii, imsld_activity_descs lad, imsld_learning_activitiesi la,
        cr_items cr1, cr_items cr2,
        acs_rels ar
        where la.item_id = :activity_item_id
        and la.activity_description_id = cr1.item_id
        and cr1.live_revision = lad.description_id
        and ar.object_id_one = la.activity_description_id
        and ar.object_id_two = cr2.item_id
        and cr2.live_revision = ii.imsld_item_id
    }]
    foreach imsld_item_id $linear_item_list {
        db_foreach la_nested_associated_items {
            select cpr.resource_id,
            cpr.item_id as resource_item_id,
            cpr.type as resource_type
            from imsld_cp_resourcesi cpr, imsld_itemsi ii,
            acs_rels ar
            where ar.object_id_one = ii.item_id
            and ar.object_id_two = cpr.item_id
            and content_revision__is_live(cpr.resource_id) = 't'
            and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 or ii.imsld_item_id = :imsld_item_id)
        } {
            if {[string eq "t" $resource_mode] } { 
                lappend la_resource_item_list $resource_item_id
            }
            
            set one_activity_urls "[imsld::process_resource -resource_item_id $resource_item_id]"
            if { [string eq "" $one_activity_urls] } {
                lappend activity_items_list "[_ imsld.lt_li_desc_no_file_assoc]"
            } else {
                if { [llength $activity_items_list] } {
                    set activity_items_list [concat $activity_items_list [list $one_activity_urls]]
                } else {
                    set activity_items_list [list $one_activity_urls]
                }
            }
            if {[string eq "t" $resource_mode] } { 
                lappend activity_items_list $la_resource_item_list
            }
           
        } if_no_rows {
            ns_log notice "[_ imsld.lt_li_desc_no_file_assoc]"
        }
    }

    # feedback
    set feedbacks_list [list]
    if { ![string eq "" $on_completion_item_id] } {
        set feedbacks_list [imsld::process_feedback -on_completion_item_id $on_completion_item_id]
    }
    if {[string eq "t" $resource_mode]} {
        #put in order the environments_id(s)
        set environments_ids [concat [lindex [lindex $environments_list 1] [expr [llength [lindex $environments_list 1] ] - 1 ]] \
                                     [lindex [lindex $environments_list 2] [expr [llength [lindex $environments_list 2] ] - 1 ]] ]

         return [list [lindex $prerequisites_list [expr [llength $prerequisites_list] - 1]] \
                      [lindex $objectives_list [expr [llength $objectives_list ] - 1]]\
                      $environments_ids \
                      [lindex $activity_items_list [expr [llength $activity_items_list ] - 1]]]

    } else {
        return [list $prerequisites_list $objectives_list $environments_list $activity_items_list $feedbacks_list]
    }
}

ad_proc -public imsld::process_support_activity { 
    -activity_item_id:required
    {-community_id ""}
} {
    @param activity_item_id
    
    @return The list of items (resources, feedback, environments) associated with the support activity
} {
    db_1row activity_info {
        select on_completion_id as on_completion_item_id,
        activity_id
        from imsld_support_activitiesi
        where item_id = :activity_item_id
        and content_revision__is_live(activity_id) = 't'
    }

    # get environments
    set environments_list [list]
    set associated_environments_list [db_list sa_associated_environments {
        select ar.object_id_two as environment_item_id
        from acs_rels ar
        where ar.object_id_one = :activity_item_id
        and ar.rel_type = 'imsld_sa_env_rel'
        order by ar.object_id_two
    }]
    foreach environment_item_id $associated_environments_list {
        if { [llength $environments_list] } {
            set environments_list [concat [list $environments_list] \
                                       [list [imsld::process_environment -environment_item_id $environment_item_id]]]
        } else {
            set environments_list [imsld::process_environment -environment_item_id $environment_item_id]
        }
    }

    set activity_items_list [list]
    # get the items associated with the activity
    set linear_item_list [db_list item_linear_list {
        select ii.imsld_item_id
        from imsld_items ii, imsld_activity_descs sad, imsld_support_activitiesi sa,
        cr_items cr1, cr_items cr2,
        acs_rels ar
        where sa.item_id = :activity_item_id
        and sa.activity_description_id = cr1.item_id
        and cr1.live_revision = sad.description_id
        and ar.object_id_one = sa.activity_description_id
        and ar.object_id_two = cr2.item_id
        and cr2.live_revision = ii.imsld_item_id
    }]
    foreach imsld_item_id $linear_item_list {
        db_foreach sa_nested_associated_items {
            select cpr.resource_id,
            cpr.item_id as resource_item_id,
            cpr.type as resource_type
            from imsld_cp_resourcesi cpr, imsld_itemsi ii,
            acs_rels ar
            where ar.object_id_one = ii.item_id
            and ar.object_id_two = cpr.item_id
            and content_revision__is_live(cpr.resource_id) = 't'
            and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 or ii.imsld_item_id = :imsld_item_id)
        } {
            set one_activity_urls "[imsld::process_resource -resource_item_id $resource_item_id]"
            if { [string eq "" $one_activity_urls] } {
                lappend activity_items_list "[_ imsld.lt_li_desc_no_file_assoc]"
            } else {
                if { [llength $activity_items_list] } {
                    set activity_items_list [concat $activity_items_list [list $one_activity_urls]]
                } else {
                    set activity_items_list [list $one_activity_urls]
                }
            }
        } if_no_rows {
            ns_log notice "[_ imsld.lt_li_desc_no_file_assoc]"
        }
    }

    # feedback
    set feedbacks_list [list]
    if { ![string eq "" $on_completion_item_id] } {
        set feedbacks_list [imsld::process_feedback -on_completion_item_id $on_completion_item_id]
    }
    return [list $environments_list \
                $activity_items_list \
                $feedbacks_list]
}

ad_proc -public imsld::process_activity_structure {
    -structure_item_id:required
} {
    @param structure_item_id
    
    @return The list of items (environments) associated with the activity structure
} {
    # get environments
    set environments_list [list]
    set associated_environments_list [db_list sa_associated_environments {
        select ar.object_id_two as environment_item_id
        from acs_rels ar
        where ar.object_id_one = :structure_item_id
        and ar.rel_type = 'imsld_as_env_rel'
        order by ar.object_id_two
    }]
    foreach environment_item_id $associated_environments_list {
        if { [llength $environments_list] } {
            set environments_list [concat [list $environments_list] \
                                       [list [imsld::process_environment -environment_item_id $environment_item_id]]]
        } else {
            set environments_list [imsld::process_environment -environment_item_id $environment_item_id]
        }
    }
    return $environments_list
}

ad_proc -public imsld::next_activity { 
    -imsld_item_id:required
    {-user_id ""}
    {-community_id ""}
    -return_url
    imsld_multirow
} {
    @param imsld_item_id
    @option user_id default [ad_conn user_id]
    @option community_id
    @param return_url url to return in the action links
    
    @return The list (activity_name, list of associated urls) of the next activity for the user in the IMS-LD.
} {
    template::multirow create imsld_multirow prerequisites  \
                                             objectives  \
                                             environments  \
                                             activities  \
                                             feedbacks  \
                                             status 
    # environments
    set environments_titles ""
    set environments_files ""

    db_1row get_ismld_info {
        select imsld_id
        from imsld_imsldsi
        where item_id = :imsld_item_id
        and content_revision__is_live(imsld_id) = 't'
    }
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
   
    # global prerequisites and learning objectives

    set prerequisites_list_temp [imsld::process_prerequisite -imsld_item_id $imsld_item_id -resource_mode "t"]
    set prerequisites_list [list [lindex $prerequisites_list_temp 0] [lindex $prerequisites_list_temp 1]]
    set prerequisites_list_ids [lindex $prerequisites_list_temp 2]
    
    set prerequisites ""
    if { [llength $prerequisites_list] } {
        set prerequisites "[lindex $prerequisites_list 0]" 
        append prerequisites "[join [lindex $prerequisites_list 1] " "]"
    }
    
    set objectives_list_temp [imsld::process_learning_objective -imsld_item_id $imsld_item_id -resource_mode "t"]
    set objectives_list [list [lindex $objectives_list_temp 0] [lindex $objectives_list_temp 1]]
    set objectives_list_ids [lindex $objectives_list_temp 2]
    
    set objectives ""
    if { [llength $objectives_list] } {
        set objectives "[lindex $objectives_list 0] <br/>"
        append objectives "[join [lindex $objectives_list 1] " "]"
    }
    if { [string length "${prerequisites}${objectives}"] } {
        template::multirow append imsld_multirow $prerequisites $objectives {} {} {} {}

        foreach the_resource_id [join [list $prerequisites_list_ids $objectives_list_ids]] {
                if {![db_0or1row get_object_from_resource {}]} {
                    db_1row get_cr_item_from_resource {} 
                    permission::grant -party_id $user_id -object_id $the_object_id  -privilege "read"
                } else {
                    permission::grant -party_id $user_id -object_id $the_object_id  -privilege "read"
                }
            }
    }
    
    if { ![db_string get_last_entry {
        select count(*)
        from imsld_status_user
        where user_id = :user_id
        and imsld_id = :imsld_id
    }] } {
        # special case: the user has no entry, the ims-ld hasn't started yet for that user
        set first_p 1
        db_1row get_first_role_part {
            select irp.role_part_id
            from cr_items cr0, cr_items cr1, cr_items cr2, imsld_methods im, imsld_plays ip, imsld_acts ia, imsld_role_parts irp
            where im.imsld_id = :imsld_item_id
            and ip.method_id = cr0.item_id
            and cr0.live_revision = im.method_id
            and ia.play_id = cr1.item_id
            and cr1.live_revision = ip.play_id
            and irp.act_id = cr2.item_id
            and cr2.live_revision = ia.act_id
            and content_revision__is_live(irp.role_part_id) = 't'
            and ip.sort_order = (select min(ip2.sort_order) from imsld_plays ip2 where ip2.method_id = cr0.item_id)
            and ia.sort_order = (select min(ia2.sort_order) from imsld_acts ia2 where ia2.play_id = cr1.item_id)
            and irp.sort_order = (select min(irp2.sort_order) from imsld_role_parts irp2 where irp2.act_id = cr2.item_id)
        }
    } else {
        # get the completed activities in order to display them
        # save the last one (the last role_part_id of THE LAST completed activity) because we will use it latter

        # JOPEZ: needed to split the db_foreach from the body because of db pools
        foreach completed_activity [db_list_of_lists completed_activity {
            select stat.completed_id,
            stat.role_part_id,
            stat.type,
            rp.sort_order,
            rp.act_id
            from imsld_status_user stat, imsld_role_parts rp
            where stat.imsld_id = :imsld_id
            and stat.user_id = :user_id
            and stat.role_part_id = rp.role_part_id
            and stat.type in ('learning','support','structure')
            order by stat.finished_date
        }] {
            set completed_id [lindex $completed_activity 0]
            set role_part_id [lindex $completed_activity 1]
            set type [lindex $completed_activity 2]
            set sort_order [lindex $completed_activity 3]
            set act_id [lindex $completed_activity 4]
            # environments
            set environment_list [list]
            set environments ""
            switch $type {
                learning {
                    db_1row get_learning_activity_info {
                        select coalesce(title,identifier) as activity_title,
                        item_id as activity_item_id
                        from imsld_learning_activitiesi
                        where activity_id = :completed_id
                    }
                    set activities_list [imsld::process_learning_activity -activity_item_id $activity_item_id]
                   
                    set prerequisites ""
                    if { [llength [lindex $activities_list 0]] } {
                        set prerequisites "[lindex [lindex $activities_list 0] 0] <br/>"
                        append prerequisites "[join [lindex [lindex $activities_list 0] 1] " "]"
                    }
                    set objectives ""
                    if { [llength [lindex $activities_list 1]] } {
                        set objectives "[lindex [lindex $activities_list 1] 0] <br/>"
                        append objectives "[join [lindex [lindex $activities_list 1] 1] " "]"
                    }
                    if { [llength [lindex $activities_list 2]] } {
                        set environments "[lindex [lindex $activities_list 2] 0] <br/>"
                        append environments "[join [lindex [lindex $activities_list 2] 1] " "] "
                        append environments "[join [lindex [lindex $activities_list 2] 2] " "] "
                        append environments "[join [lindex [lindex $activities_list 2] 3] " "]"
                    }
                    
                    set activities "$activity_title <br /> [join [lindex $activities_list 3] " "]"

                    set feedbacks ""
                    if { [llength [lindex $activities_list 4]] } {
                        set feedbacks "[lindex [lindex $activities_list 4] 0] <br/>"
                        append feedbacks "[join [lindex [lindex $activities_list 4] 1] " "]"
                    }

                    set resources_activities_list [imsld::process_learning_activity -activity_item_id $activity_item_id -resource_mode "t"]
                    foreach resource_activity [join $resources_activities_list] {

                        
#assessment must have an extra feedback item
                       if {[db_0or1row is_assessment {} ] } {
                            db_1row get_as_site_node {} 
                            set as_feedback_url "[site_node::get_url -node_id $node_id][export_vars -base sessions {assessment_id $assessment_id}]"
                            set as_feedback_link "<a href=[export_vars -base $as_feedback_url] target=\"_blank\"><img src=\"[lindex [site_node::get_url_from_object_id -object_id [ad_conn package_id]] 0][imsld::package_key]/resources/sessions.png\" border=0  alt=\"$as_feedback_url\"></a>"
                            append feedbacks $as_feedback_link
                       } 
                    }
                    
                    template::multirow append imsld_multirow $prerequisites \
                        $objectives \
                        $environments \
                        $activities \
                        $feedbacks \
                        finished
                }
                support {
                    db_1row get_support_activity_info_from_isa {
                        select coalesce(title,identifier) as activity_title,
                        item_id as activity_item_id
                        from imsld_support_activitiesi
                        where activity_id = :completed_id
                    }
                    set activities_list [imsld::process_support_activity -activity_item_id $activity_item_id]

                    if { [llength [lindex $activities_list 0]] } {
                        set environments "[lindex [lindex $activities_list 0] 0] <br/>"
                        append environments "[join [lindex [lindex $activities_list 0] 1] " "] "
                        append environments "[join [lindex [lindex $activities_list 0] 2] " "] "
                        append environments "[join [lindex [lindex $activities_list 0] 3] " "] "
                    }

                    set activities "$activity_title <br /> [join [lindex $activities_list 1] " "]"

                    set feedbacks ""
                    if { [llength [lindex $activities_list 2]] } {
                        set feedbacks "[lindex [lindex $activities_list 2] 0] <br/>"
                        append feedbacks "[join [lindex [lindex $activities_list 2] 1] " "]"
                    }
                    template::multirow append imsld_multirow {} \
                        {} \
                        $environments \
                        $activities \
                        $feedbacks \
                        finished
                }
                structure {
                    db_1row get_support_activity_info_from_ias {
                        select coalesce(title,identifier) as activity_title,
                        item_id as structure_item_id
                        from imsld_activity_structuresi
                        where structure_id = :completed_id
                    }
                    set structure_envs [imsld::process_activity_structure -structure_item_id $structure_item_id]
                    set environments ""
                    foreach structure_list $structure_envs {
                        if { [llength [lindex $structure_list 0]] } {
                            append environments "[lindex $structure_list 0] <br/>"
                            append environments "[join [lindex $structure_list 1] " "] "
                            append environments "[join [lindex $structure_list 2] " "] "
                            append environments "[join [lindex $structure_list 3] " "]<br/>"
                        }
                    }
                    template::multirow append imsld_multirow {} {} $environments $activity_title {} finished
                }
            }
        }
        
        # the last completed is now stored in completed_id, let's find out the next role_part_id that the user has to work on.
        # Procedure (knowing that the info of the last role_part are stored in the last iteration vars):
        # 0. check if all the activities referenced by the current role_part_id are finished
        # 0.1 if all of them are not finished yet, skip this section and preserve the last role_part_id, otherwise, continue
        # 1. get the next role_part from imsld_role_parts according to sort_number, first 
        #    search in the current act_id, then in the current play_id, then in the next play_id and so on...
        # 1.1 if there are no more role_parts then this is the last one
        # 1.2 if we find a "next role_part", it will be treated latter, we just have to set the next role_part_id var

        if { [imsld::role_part_finished_p -role_part_id $role_part_id -user_id $user_id] } {
            # search in the current act_id
            if { ![db_0or1row search_current_act {
                select role_part_id
                from imsld_role_parts
                where sort_order = :sort_order + 1
                and act_id = :act_id
            }] } {
                # get current act_id's sort_order and search in the next act in the current play_id
                db_1row get_current_play_id {
                    select ip.item_id as play_item_id,
                    ip.play_id,
                    ia.sort_order as act_sort_order
                    from imsld_playsi ip, imsld_acts ia, cr_items cr
                    where ip.item_id = ia.play_id
                    and ia.act_id = cr.live_revision
                    and cr.item_id = :act_id
                }
                if { ![db_0or1row search_current_play {
                    select rp.role_part_id
                    from imsld_role_parts rp, imsld_actsi ia
                    where ia.play_id = :play_item_id
                    and ia.sort_order = :act_sort_order + 1
                    and rp.act_id = ia.item_id
                    and content_revision__is_live(rp.role_part_id) = 't'
                    and content_revision__is_live(ia.act_id) = 't'
                    and rp.sort_order = (select min(irp2.sort_order) from imsld_role_parts irp2 where irp2.act_id = rp.act_id)
                }] } {
                    # get the current play_id's sort_order and sarch in the next play in the current method_id
                    db_1row get_current_method {
                        select im.item_id as method_item_id,
                        ip.sort_order as play_sort_order
                        from imsld_methodsi im, imsld_plays ip
                        where im.item_id = ip.method_id
                        and ip.play_id = :play_id
                    }
                    if { ![db_0or1row search_current_method {
                        select rp.role_part_id
                        from imsld_role_parts rp, imsld_actsi ia, imsld_playsi ip
                        where ip.method_id = :method_item_id
                        and ia.play_id = ip.item_id
                        and rp.act_id = ia.item_id
                        and ip.sort_order = :play_sort_order + 1
                        and content_revision__is_live(rp.role_part_id) = 't'
                        and content_revision__is_live(ia.act_id) = 't'
                        and content_revision__is_live(ip.play_id) = 't'
                        and ia.sort_order = (select min(ia2.sort_order) from imsld_acts ia2 where ia2.play_id = ip.item_id)
                        and rp.sort_order = (select min(irp2.sort_order) from imsld_role_parts irp2 where irp2.act_id = ia.item_id)
                    }] } {
                        # there is no more to search, we reached the end of the unit of learning
                        template::multirow append imsld_multirow {} {} {} {} {} "[_ imsld.lt_Learning_Unit_finishe]"
                        return [template::multirow size imsld_multirow]
                    }
                }
            }
        }
    }
    # find the next activity referenced by the role_part
    # (learning_activity, support_activity, activity_structure)  
    # 1. if it is a learning or support activity, no problem, find the associated files and return the lists
    # 2. if it is an activity structure we have verify which activities are already completed and return the next
    #    activity in the activity structure, handling the case when the next activity is also an activity structure

    db_1row get_role_part_activity {
        select case
        when learning_activity_id is not null
        then 'learning'
        when support_activity_id is not null
        then 'support'
        when activity_structure_id is not null
        then 'structure'
        else 'none'
        end as activity_type,
        case
        when learning_activity_id is not null
        then content_item__get_live_revision(learning_activity_id)
        when support_activity_id is not null
        then content_item__get_live_revision(support_activity_id)
        when activity_structure_id is not null
        then content_item__get_live_revision(activity_structure_id)
        else content_item__get_live_revision(environment_id)
        end as activity_id,
        environment_id as rp_environment_item_id
        from imsld_role_parts
        where role_part_id = :role_part_id
    }

    # environments
    set environment_list [list]
    set environments ""
    # get the environments associated to the role_part
    if { ![string eq "" $rp_environment_item_id] } {
        set environment_list [concat [list $environment_list] [imsld::process_environment -environment_item_id $rp_environment_item_id]]
    }
    
    # activity structure
    if { [string eq $activity_type structure] } {
        # activity structure. we have to look for the next learning or support activity
        set activity_list [imsld::structure_next_activity -activity_structure_id $activity_id -environment_list $environment_list]
        set activity_id [lindex $activity_list 0]
        set activity_type [lindex $activity_list 1]
        if { [llength $environment_list] } {
            set environment_list [concat [list $environment_list] [lindex $activity_list 2]]
        } else {
            set environment_list [lindex $activity_list 2]
        }
    }
    set environments ""
    if { [llength $environment_list] } {
        foreach environment $environment_list {
            append environments "[lindex $environment 0] <br/>"
            append environments "[join [lindex $environment 1] " "] "
            append environments "[join [lindex $environment 2] " "] "
            append environments "[join [lindex $environment 3] " "]<br/>"
        }
    }
    
    # learning activity
    if { [string eq $activity_type learning] } {
        db_1row learning_activity {
            select la.activity_id,
            la.item_id as activity_item_id,
            la.title as activity_title,
            la.identifier
            from imsld_learning_activitiesi la
            where la.activity_id = :activity_id
        }
        set activities_list [imsld::process_learning_activity -activity_item_id $activity_item_id]

                    set resources_activities_list [imsld::process_learning_activity -activity_item_id $activity_item_id -resource_mode "t"]
                    foreach resource_activity [join $resources_activities_list] {

#grant permissions for newly appeared resources
                         foreach the_resource_id [join $resources_activities_list] {
                            if {![db_0or1row get_object_from_resource {}]} {
                                db_1row get_cr_item_from_resource {} 
 
                                permission::grant -party_id $user_id -object_id $the_object_id  -privilege "read"
                            } else {

                                permission::grant -party_id $user_id -object_id $the_object_id  -privilege "read"
                            }
                        } 
                    }

            
        set prerequisites ""
        if { [llength [lindex $activities_list 0]] } {
            set prerequisites "[lindex [lindex $activities_list 0] 0] <br/>"
            append prerequisites "[join [lindex [lindex $activities_list 0] 1] " "]"
        }
        set objectives ""
        if { [llength [lindex $activities_list 1]] } {
            set objectives "[lindex [lindex $activities_list 1] 0] <br/>"
            append objectives "[join [lindex [lindex $activities_list 1] 1] " "]"
        }
        if { [llength [lindex $activities_list 2]] } {
            set environments "[lindex [lindex $activities_list 2] 0] <br/>"
            append environments "[join [lindex [lindex $activities_list 2] 1] " "] "
            append environments "[join [lindex [lindex $activities_list 2] 2] " "] "
            append environments "[join [lindex [lindex $activities_list 2] 3] " "]"
        }
        set files ""
        set activities "$activity_title <br /> [join [lindex $activities_list 3] " "]"

        template::multirow append imsld_multirow $prerequisites \
            $objectives \
            $environments \
            $activities \
            {} \
            "<a href=finish-component-element-${imsld_id}-${role_part_id}-${activity_id}-learning.imsld>finish</a>"
    }

    # support activity
    if { [string eq $activity_type support] } {
        db_1row support_activity {
            select sa.activity_id,
            sa.item_id as activity_item_id,
            sa.title as activity_title,
            sa.identifier
            from imsld_support_activitiesi sa
            where sa.activity_id = :activity_id
        }
        set activities_list [imsld::process_support_activity -activity_item_id $activity_item_id]
        
        if { [llength [lindex $activities_list 0]] } {
            set environments "[lindex [lindex $activities_list 0] 0]<br/>"
            append environments "[join [lindex [lindex $activities_list 0] 1] " "] "
            append environments "[join [lindex [lindex $activities_list 0] 2] " "] "
            append environments "[join [lindex [lindex $activities_list 0] 3] " "]"
            regsub -all {<li>[ ]*</li>} $environments "" environments
        }

        set activities "$activity_title <br /> [join [lindex $activities_list 1] " "]"
        
        template::multirow append imsld_multirow {} \
            {} \
            $environments \
            $activities \
            {} \
            "<a href=finish-component-element-${imsld_id}-${role_part_id}-${activity_id}-support.imsld>finish</a>"
    }
        
    # this should never happen, but in case the next activiy is already finished, let's throw an error
    # instead of doing nothing
    if { [db_string verify_not_completed {
        select count(*) from imsld_status_user
        where completed_id = :activity_id
        and user_id = :user_id
    }] } {
        return -code error "IMSLD::imsld::next_activity: Returning a completed activity!"
        ad_script_abort
    }
    
    # first parameter: activity name
    return [template::multirow size imsld_multirow]
}

ad_proc -public imsld::get_activity_from_resource { 
   -resource_id
} { 
    @return The a list of the activity_id, activity_item_id and activity_type from which the resource is being referenced
} {
    #set a flag. while 1, keep trying
    
    # Case 1: check if it is referenced from a learning activity (trhough the activity_description)
    set activity_item_id ""
    if { [db_0or1row learning_activity_resource {
        select ila.activity_id,
        ila.item_id as activity_item_id
        from imsld_cp_resourcesi icri,
        acs_rels ar1,
        acs_rels ar2,
        imsld_learning_activitiesi ila 
        where ar2.object_id_two=icri.item_id 
        and ar1.object_id_two=ar2.object_id_one 
        and ila.activity_description_id=ar1.object_id_one 
        and icri.resource_id= :resource_id
    }] } {
        # found it, it's referenced from a learning activity
        return [list $activity_id $activity_item_id learning]
    }

    # Case 2: check if it is referenced from a support activity (trhough the activity_description)
    set activity_item_id ""
    if { [db_0or1row support_activity_resource {
        select isa.activity_id,
        isa.item_id as activity_item_id
        from imsld_cp_resourcesi icri,
        acs_rels ar1,
        acs_rels ar2,
        imsld_support_activitiesi isa 
        where ar2.object_id_two=icri.item_id 
        and ar1.object_id_two=ar2.object_id_one 
        and isa.activity_description_id=ar1.object_id_one 
        and icri.resource_id= :resource_id
    }] } {
        # found it, it's referenced from a support activity
        return [list $activity_id $activity_item_id support]
    }

    # Case 3: check if it is referenced from a service

    # first get the imsld_item_id
    db_1row get_imsld_item_id { 
        select ar1.object_id_one as imsld_item_item_id 
        from imsld_cp_resourcesi icri,
        acs_rels ar1 
        where icri.item_id=ar1.object_id_two 
        and icri.resource_id= :resource_id
    }

    # there are three options: a service, a conference service or a learning object

    # FIX ME: VALID ONLY FOR CONFERENCE_SERVICES!!!
    if { [db_0or1row is_conference_service {select 1 from imsld_conference_services where imsld_item_id=:imsld_item_item_id} ] } {
        # conference service
        # get the environment_id
        db_1row get_environment_id_from_cs {
            select isi.environment_id as environment_item_id 
            from imsld_conference_services ics,
            imsld_servicesi isi 
            where isi.item_id=ics.service_id 
            and ics.imsld_item_id=:imsld_item_item_id
        }
        
        # evironment referenced from learning activity ?
        if { [db_0or1row get_learning_activity_from_environment {
                select ila.activity_id,
                       ila.item_id as activity_item_id 
                    from acs_rels ar,
                         imsld_learning_activitiesi ila 
                    where ila.item_id=ar.object_id_one 
                         and ar.object_id_two=:environment_item_id
        }] } {
            return [list $activity_id $activity_item_id learning]
        }

        # evironment referenced from support activity ?
        if { [db_0or1row get_support_activity_from_environment {
                select isa.activity_id,
                       isa.item_id as activity_item_id 
                    from acs_rels ar,
                         imsld_support_activitiesi isa 
                    where isa.item_id=ar.object_id_one 
                         and ar.object_id_two=:environment_item_id
        }] } {
            return [list $activity_id $activity_item_id support]
        }
    }
    

    # Case 4: learning objects
    if { [db_0or1row is_learning_object {
        select 1 from acs_rels where rel_type='imsld_l_object_item_rel' and object_id_two=:imsld_item_item_id 
    } ] } {
        db_1row get_environment_id_from_lo {
                select iloi.environment_id as environment_item_id 
                from imsld_learning_objectsi iloi,
                     acs_rels ar 
                where iloi.item_id=ar.object_id_one
                     and ar.object_id_two=:imsld_item_item_id
        }

        # learning object referenced from a learning activity ?
        if { [db_0or1row get_learning_activity_from_environment {
                    select ila.activity_id,
                           ila.item_id as activity_item_id 
                    from acs_rels ar,
                         imsld_learning_activitiesi ila 
                    where ila.item_id=ar.object_id_one 
                         and ar.object_id_two=:environment_item_id
        }] } {
            return [list $activity_id $activity_item_id learning]
        }

        # learning object referenced from a support activity ?
        if { [db_0or1row get_support_activity_from_environment {
                    select isa.activity_id,
                           isa.item_id as activity_item_id 
                    from acs_rels ar,
                         imsld_support_activitiesi isa 
                    where isa.item_id=ar.object_id_one 
                         and ar.object_id_two=:environment_item_id
        }] } {
            return [list $activity_id $activity_item_id support]
        }
    }

    # Case 5: the last one. it has to be referenced fron a learning objective or prerequisite,
    # which is referenced from a larning activity

    #get the element with which the resource is asociated (prerequisite,learning objective,environment or learning activity)
    db_1row get_activity_from_resource { 
        select ar1.object_id_one as resource_element_id
        from acs_rels ar1,
        acs_rels ar2,
        imsld_cp_resourcesi icr 
        where ar1.object_id_two=ar2.object_id_one 
        and ar2.object_id_two=icr.item_id 
        and icr.resource_id = :resource_id;
    }
            
    # prerequisite ?
    if { [db_0or1row is_prerequisite { select 1 from imsld_prerequisitesi where item_id=:resource_element_id }] } {
        db_1row get_activity_id_from_prerequisite {
            select activity_id,
            item_id as activity_item_id 
            from imsld_learning_activitiesi 
            where prerequisite_id=:resource_element_id 
        }
        return [list $activity_id $activity_item_id learning]
    } elseif { [db_0or1row is_learning_objective { select 1 from imsld_learning_objectivesi where item_id=:resource_element_id } ] } {
        # learning objective?
        db_1row get_activity_id_from_objective {
            select activity_id,
            item_id as activity_item_id
            from imsld_learning_activitiesi
            where learning_objective_id=:resource_element_id
        }
        return [list $activity_id $activity_item_id support]
    } 
    return -code error "IMSLD::imsld::get_activity_from_resource no activity_id found for resource"
}

ad_proc -public imsld::get_imsld_from_activity { 
   -activity_id
} { 
    @return The imsld_id from which the activity is being used.
} {
    db_1row get_imsld_from_activity {
            select iii.imsld_id as imsld_id
            from imsld_imsldsi iii,
                 cr_items cr,
                 cr_items cr2,
                 imsld_learning_activitiesi ilai 
            where ilai.activity_id=:activity_id
                 and ilai.item_id=cr.item_id 
                 and cr2.parent_id=cr.parent_id 
                 and cr2.content_type='imsld_imsld' 
                 and iii.item_id=cr2.item_id

    }
    return $imsld_id
}

ad_proc -public imsld::get_resource_from_object {
    -object_id
} {
    <p>Get the object which is asociated with an acs_object_id</p>
    @author Luis de la Fuente Valentín (lfuente@it.uc3m.es)
} {
    db_1row get_resource {
        select resource_id
        from imsld_cp_resources
        where acs_object_id = :object_id
    }
    return $resource_id
}

ad_proc -public imsld::finish_resource {
    -resource_id
} {
    <p>Tag a resource as finished into an activity. Return true if success, false otherwise</p>

    @author Luis de la Fuente Valentín (lfuente@it.uc3m.es)
} {


#look for the asociated activity
    # get the activity_id, activity_item_id and activity_type
    set activity_list [imsld::get_activity_from_resource -resource_id $resource_id]
    set activity_id [lindex $activity_list 0]
    set activity_item_id [lindex $activity_list 1]
    set activity_type [lindex $activity_list 2]

    
#get info
    set role_part_id [imsld::get_role_part_from_activity -activity_type learning -leaf_id $activity_item_id]
    set imsld_id [imsld::get_imsld_from_activity -activity_id $activity_id]
    set user_id [ad_conn user_id]

   
#if not done yet, tag the resource as finished
    if { ![db_string check_completed_resource {
        select count(*)
        from imsld_status_user 
        where completed_id=:resource_id
        and user_id = :user_id
    }] } {
        db_dml insert_completed_resource {
            insert into imsld_status_user (
                                           imsld_id,
                                           role_part_id,
                                           completed_id,
                                           user_id,
                                           type,
                                           finished_date
                                           )
            (
             select :imsld_id,
             :role_part_id,
             :resource_id,
             :user_id,
             'resource',
             now()
             where not exists (select 1 from imsld_status_user where imsld_id = :imsld_id and user_id = :user_id and completed_id = :resource_id)
             )
        }
        
#find all the resouces in the same activity 
        set first_resources_item_list [imsld::process_learning_activity -activity_item_id $activity_item_id -resource_mode "t"]

#only the learning_activities must be finished
        set resources_item_list [lindex $first_resources_item_list 3]
        if { [llength $resources_item_list] == 0 } {
            set resources_item_list [lindex $first_resources_item_list 2]
        }
        
        set all_finished_p 1
        foreach resource_item_id $resources_item_list { 
            foreach res_id $resource_item_id {
                if { ![db_0or1row resource_finished_p {
                    select 1 
                    from imsld_status_user stat, imsld_cp_resourcesi icr
                    where icr.item_id = :res_id
                    and icr.resource_id = stat.completed_id
                    and user_id = :user_id
                }] } {
                    # if the resource is not in the imsld_status_user, then the resource is not finished
                    set all_finished_p 0
                    break
                }
            }
        }

#if all are finished, tag the activity as finished
        if { $all_finished_p && ![db_0or1row already_finished { *SQL* }] } {
            imsld::finish_component_element -imsld_id $imsld_id  \
                -role_part_id $role_part_id \
                -element_id $activity_id \
                -type $activity_type\
                -code_call
        }
    }
}


ad_register_proc GET /finish-component-element* imsld::finish_component_element
ad_register_proc POST /finish-component-element* imsld::finish_component_element
