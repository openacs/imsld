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

    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set item_name "${item_id}_content_type"
    set title [expr { [empty_string_p $title] ? $item_name : $title }]
    
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
    
    if { ![empty_string_p $attributes] } {
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
} { 
} {  
    # get the url for parse it and get the info
    set url [ns_conn url]
    regexp {finish-component-element-([0-9]+)-([0-9]+)-([0-9]+)-([a-z]+).imsld$} $url match imsld_id role_part_id element_id type
    regsub {/finish-component-element.*} $url "" return_url 
    set user_id [ad_conn user_id]
    # now that we have the necessary info, mark the finished element completed and return
    db_dml insert_entry {
        insert into imsld_status_user
        values (
                :imsld_id,
                :role_part_id,
                :element_id,
                :user_id,
                :type,
                now()
                )
    }

    ad_returnredirect "[ad_url]${return_url}"
} 

ad_proc -public imsld::next_activity { 
    -imsld_item_id:required
    {-user_id ""}
    {-community_id ""}
    -return_url
} { 
    @param imsld_item_id
    @option user_id default [ad_conn user_id]
    @option community_id
    @param return_url url to return in the action links
    
    @return The list (activity_name, list of associated urls) of the next activity for the user in the IMS-LD.
} {
    set community_id [expr { [empty_string_p $community_id] ? "[dotlrn_community::get_community_id]" : $community_id }]
    # Gets file-storage root folder_id
    set fs_package_id [site_node_apm_integration::get_child_package_id \
                           -package_id [dotlrn_community::get_package_id $community_id] \
                           -package_key "file-storage"]
    set root_folder_id [fs::get_root_folder -package_id $fs_package_id]
    db_1row get_ismld_id {
        select imsld_id
        from imsld_imsldsi
        where item_id = :imsld_item_id
        and content_revision__is_live(imsld_id) = 't'
    }
    set completed_activities ""
    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    if { ![db_string get_last_entry {
        select count(*)
        from imsld_status_user
        where user_id = :user_id
        and imsld_id = :imsld_id
    }] } {
        # special case: the user has no entry, the ims-ld hasn't started yet for that user
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
        # save the last one because we will use it latter
        set completed_activities "[_ imsld.lt_ul_Completed_Activiti]"
        db_foreach completed_activity {
            select stat.completed_id,
            stat.role_part_id,
            stat.type,
            rp.sort_order,
            rp.act_id
            from imsld_status_user stat, imsld_role_parts rp
            where stat.imsld_id = :imsld_id
            and stat.user_id = :user_id
            and stat.role_part_id = rp.role_part_id
            order by stat.finished_date
        } {
            switch $type {
                learning {
                    if { [db_string referenced_p {
                        select count(*) 
                        from imsld_role_parts irp, imsld_learning_activities la, cr_items cr
                        where irp.learning_activity_id = cr.item_id
                        and cr.live_revision = la.activity_id
                        and la.activity_id = :completed_id
                    }] } {
                        # the learning activity is referenced directly from the role part, everything it's ok!
                        db_1row get_learning_activity_info {
                            select coalesce(title,identifier) as activity_title
                            from imsld_learning_activitiesi
                            where activity_id = :completed_id
                        }
                        append completed_activities "[_ imsld.li_activity_title_li]"
                    } else {
                        # the learning activity is referenced from an activity structure... digg more
                        append completed_activities "[_ imsld.li_impozzible_li]"
                    }
                }
                support {
                }
                structure {
                }
                default {
                    ad_return_error "[_ imsld.lt_Invalid_type_type_in_]" "[_ imsld.lt_Valid_types_are_learn]"
                    ad_script_abort
                }
            }
        }
        append completed_activities "</ul>"
        # !!!
        # the last completed is now stored in completed_id, let's find out the next role_part_id the user has to work on.
        # Procedure (knowing that the info of the last role_part are stored in the last iteration vars):
        # 1. get the next role_part from imsld_role_parts according to sort_number, first 
        #    search in the current act_id, then in the current play_id, then in the next play_id and so on...
        # 1.1 if there are no more role_parts then this is the last one
        # 1.2 if we find a "next role_part", it will be treated latter, we just have to set the next role_part_id var
        
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
                    return [list { "[_ imsld.finished]" } {} "$completed_activities"]
                }
            }
        }
    }

    # !!!
    # we assume thet the role_part_id can't have references to more than one activity 
    # (learning_activity, support_activity, activity_structure)  
    # 1. if it is a learning or support activity, no problem, find the associated files and return the lists
    # 2. if it is an activity structure we have verify which activities are already completed and return the next
    #    activity in the activity structure, handling the case when the next activity is also an activity structure

    if { [db_0or1row learning_activity {
        select la.activity_id,
        la.item_id as activity_item_id,
        la.title,
        la.identifier,
        la.user_choice_p
        from imsld_learning_activitiesi la, imsld_role_parts irp,
        cr_items cr
        where irp.role_part_id = :role_part_id
        and irp.learning_activity_id = cr.item_id
        and cr.live_revision = la.activity_id
    }] } {
        # learning activity
        # !!! HERE IS WHERE WE DECIDE IF WE CALL A DOTLRN SERVICE TO SERVE THE ACTIVITY, DEPENDING ON THE IDENTIFIER ???
        # BY DEFAULT GET THE RESOURCE AND DISPLAY IT FROM THE FILE STORAGE
        set activity_name [expr { [empty_string_p $title] ? $identifier : $title }]
        set activity_urls "[_ imsld.lt_ul_Next_Activity_acti]"
        db_foreach la_associated_files {
            select cpf.imsld_file_id,
            cpf.file_name,
            cpf.item_id, cpf.parent_id
            from imsld_cp_filesx cpf, acs_rels ar1, acs_rels ar2, acs_rels ar3, imsld_cp_resources cpr, imsld_items ii, 
            imsld_activity_descs lad, imsld_learning_activities la,
            cr_items cr1, cr_items cr2, cr_items cr3, cr_items cr4
            where la.activity_id = :activity_id
            and la.activity_description_id = cr1.item_id
            and cr1.live_revision = lad.description_id
            and ar1.object_id_one = la.activity_description_id
            and ar1.object_id_two = cr2.item_id
            and cr2.live_revision = ii.imsld_item_id
            and ar2.object_id_one = cr3.item_id
            and cr3.live_revision = ii.imsld_item_id
            and ar2.object_id_two = cr4.item_id
            and cr4.live_revision = cpr.resource_id
            and ar3.object_id_one = cr4.item_id
            and ar3.object_id_two = cpf.item_id
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
            set file_url "[ad_url][apm_package_url_from_id $fs_package_id]view/${file_url}"
            append activity_urls "<li> <a href=[export_vars -base $file_url]> $file_name </a> \[ <a href=[ad_url][ad_conn url]/finish-component-element-${imsld_id}-${role_part_id}-${activity_id}-learning.imsld>finish</a> \] </li>"
        } if_no_rows {
            # the activity doesn't have any resource associated, display the default page
            append activity_urls "[_ imsld.lt_li_desc_no_file_assoc]"
        }
        append activity_urls "</ul>"
    } elseif { [db_0or1row support_activity {
        select sa.activity_id,
        sa.item_id as activity_item_id,
        sa.title,
        sa.identifier,
        sa.user_choice_p
        from imsld_support_activitiesi sa, imsld_role_parts irp,
        cr_items cr
        where irp.role_part_id = :role_part_id
        and irp.learning_activity_id = cr.item_id
        and cr.live_revision = sa.activity_id
    }] } {
        # support activity
        # !!! HERE IS WHERE WE DECIDE IF WE CALL A DOTLRN SERVICE TO SERVE THE ACTIVITY, DEPENDING ON THE IDENTIFIER ???
        # BY DEFAULT GET THE RESOURCE AND DISPLAY IT FROM THE FILE STORAGE
        set activity_name [expr { [empty_string_p $title] ? $identifier : $title }]
        set activity_urls "[_ imsld.ul_activity_name_br_]"
        db_foreach la_associated_files {
            select cpf.imsld_file_id,
            cpf.file_name
            from imsld_cp_files cpf, acs_rels ar1, acs_rels ar2, imsld_cp_resources cpr, imsld_items ii, 
            imsld_activity_descs sad, imsld_support_activities sa,
            cr_items cr1, cr_items cr2, cr_items cr3, cr_items cr4
            where sa.activity_id = :activity_id
            and sa.activity_description_id = cr1.item_id
            and cr1.live_revision = sad.description_id
            and ar1.object_id_one = sa.activity_description_id
            and ar1.object_id_two = cr2.item_id
            and cr2.live_revision = ii.imsld_item_id
            and ar2.object_id_one = cr3.item_id
            and cr3.live_revision = ii.imsld_item_id
            and ar2.object_id_two = cr4.item_id
            and cr4.live_revision = cpr.resource_id
            and cpf.resource_id = cr4.item_id
            and content_revision__is_live(cpf.imsld_file_id) = 't'
        } {
            append activity_urls "[_ imsld.li_file_name_li]"
        } if_no_rows {
            # the activity doesn't have any resource associated, display the default page
            append activity_urls "[_ imsld.lt_li_desc_no_file_assoc]"
        }
        append activity_urls "</ul>"
    } elseif { 1==3 } {
        # activity structure. we have to look for the first learning or support activity
        set activity_name "suport"
        set activity_urls "urls!"
        
    } else {
        set activity_name "... environment?"
        set activity_urls "?????"
    }
    # !! first parameter: activity name
    return [list "" "$activity_urls" "$completed_activities"]
}

ad_register_proc GET /finish-component-element* imsld::finish_component_element
ad_register_proc POST /finish-component-element* imsld::finish_component_element
