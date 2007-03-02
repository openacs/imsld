ad_library {
    Procedures in the imsld namespace for evaluating conditions.
    
    @creation-date 2006-06-21
    @author eduardo.perez@uc3m.es
    @cvs-id $Id$
}

namespace eval imsld {}
namespace eval imsld::condition {}
namespace eval imsld::expression {}
namespace eval imsld::statement {}


ad_proc -public imsld::condition::execute_all {
    -run_id
    -user_id
} {
} {
    if {![info exist user_id]} {
    	set user_id [ad_conn user_id] 
    }

    set imsld_rev_id [db_string get_imsld_rev_id {SELECT imsld_id FROM imsld_runs WHERE run_id = :run_id}]
    set imsld_id [db_string get_item_id {SELECT item_id FROM cr_revisions WHERE revision_id = :imsld_rev_id}]
    set method_rev_id [db_string get_method_rev_id {SELECT method_id FROM imsld_methods WHERE imsld_id = :imsld_id}]
    set method_id [db_string get_method_id {SELECT item_id FROM cr_revisions WHERE revision_id = :method_rev_id}]

    foreach condition_xml [db_list foreach_condition {
        SELECT condition_xml FROM imsld_conditions WHERE method_id = :method_id
    }] {
        dom parse $condition_xml document
        $document documentElement condition
        imsld::condition::execute -run_id $run_id -condition $condition -user_id $user_id
    }
}

ad_proc -public imsld::condition::execute {
    -run_id
    -condition
    -user_id
} {
} {
    if {![info exist user_id]} {
	    set user_id [ad_conn user_id] 
    }
    set ifNodes [$condition selectNodes {*[local-name()='if']}]
    set thenNodes [$condition selectNodes {*[local-name()='then']}]
    set elseNodes [$condition selectNodes {*[local-name()='else']}]
    foreach ifNode $ifNodes {
        if {[imsld::expression::eval -user_id $user_id -run_id $run_id -expression [$ifNode childNodes]]} {
            foreach thenNode $thenNodes {
                imsld::statement::execute -run_id $run_id -statement [$thenNode childNodes] -user_id $user_id
            }
        } else {
            foreach elseNode $elseNodes {
                #an else node may contain an expression or another if_then_else
#prevent for empty else nodes
                if {[$elseNode hasChildNodes]} {
                    if { [string eq [ [$elseNode selectNodes {*[position()=1] } ] localName] "if" ] } {
                        imsld::condition::execute -run_id $run_id -condition $elseNode -user_id $user_id
                    } else {
                        imsld::statement::execute -run_id $run_id -statement [$elseNode childNodes] -user_id $user_id
                    }
                }
            }
        }
    }
}

ad_proc -public imsld::condition::execute_time_role_conditions {
    -run_id
} {
} {
    foreach condition_xml [db_list get_other_conditions {
        select ici.condition_xml
        from imsld_conditionsi ici, 
        imsld_methodsi imi,
        imsld_imsldsi iii,
        imsld_runs iri 
        where ici.item_id not in (select object_id_two 
                                  from acs_rels 
                                  where (rel_type='imsld_prop_cond_rel' or rel_type='imsld_ilm_cond_rel')) 
        and ici.method_id=imi.item_id 
        and imi.imsld_id=iii.item_id 
        and iri.imsld_id=iii.imsld_id 
        and iri.run_id=:run_id
    }] {
        dom parse $condition_xml document
        $document documentElement condition_node
        imsld::condition::execute -run_id $run_id -condition $condition_node
    }
}

ad_proc -public imsld::condition::eval_when_condition_true {
    -when_condition_true_item_id:required
    -run_id:required
} {
    Executes the expression of the when-condition-true for all the roles, and if it's for all the individual users
    of the role, then the act which references when-condition-true is set to completed.
} {
    # 1. get the epression and the role from the when-condition-true table
    # 2. get all the users in the role and evaluate the expression for all of them
    # 3. if the expression is true for all of the users, mark the act as completed

    # 1. get the expression and role
    db_1row get_condition_info {
        select iri.role_id,
        iwct.expression_xml
        from imsld_when_condition_truei iwct, imsld_rolesi iri
        where iwct.item_id = :when_condition_true_item_id
        and iwct.role_id = iri.item_id
        and content_revision__is_live(iri.role_id) = 't'
    }

    # 2. evaluate the expression for all the users
    set expression_true_p 1
    dom parse $expression_xml document
    $document documentElement expression_root
    set expression [$expression_root childNodes]
    foreach member_id [imsld::roles::get_users_in_role -role_id $role_id -run_id $run_id] {
        if { ![imsld::expression::eval -run_id $run_id -expression $expression -user_id $member_id] } {
            # expression is false for one user. exit
            set expression_true_p 0
            break
        }
    }

    # 3. if the expression is true for all of the users, mark the rererencer act as completed
    db_1row get_context_info {
        select ir.imsld_id,
        ip.play_id
        from imsld_runs ir,
        imsld_methodsi im,
        imsld_playsi ip,
        imsld_imsldsi ii
        where ir.run_id = :run_id
        and ir.imsld_id = ii.imsld_id
        and im.imsld_id = ii.item_id
        and ip.method_id = im.item_id
        and content_revision__is_live(ip.play_id) = 't'
    }
    
    if { $expression_true_p } {
        # get the act_id
        db_1row get_act_from_when_cond_true_id {
            select ia.act_id
            from imsld_actsi ia,
            imsld_complete_actsi ica
            where ica.when_condition_true_id = :when_condition_true_item_id
            and ia.complete_act_id = ica.item_id
        }
        # mark the act completed for all the users in the run
        set users_in_run [db_list get_users_in_run {
            select gmm.member_id 
            from group_member_map gmm,
            imsld_run_users_group_ext iruge, 
            acs_rels ar1 
            where iruge.run_id=:run_id
            and ar1.object_id_two=iruge.group_id 
            and ar1.object_id_one=gmm.group_id 
            group by member_id
        }]
        foreach user $users_in_run {
            if { [imsld::user_participate_p -run_id $run_id -act_id $act_id -user_id $user]} {
                imsld::mark_act_finished -act_id $act_id \
                    -play_id $play_id \
                    -imsld_id $imsld_id \
                    -run_id $run_id \
                    -user_id $user
            }
        }
    }
}

ad_proc -public imsld::condition::eval_change_property_value {
    -change_property_value_xml:required
    -run_id:required
} {
    Executes the expression of the change-property-value and sets the result to the associated property.
} {
    dom parse $change_property_value_xml document
    $document documentElement change_property_value_root
    imsld::statement::execute -run_id $run_id -statement [$change_property_value_root childNodes]
}

ad_proc -public imsld::condition::eval_when_prop_value_is_set {
    -complete_act_item_id:required
    -run_id:required
} {
    Executes the expression of the when-property-value-is-set and compares the result with the referenced property. If the value is the same for both of them (or if there is no expression at all), the referenced activity is marked as completed.
} {
    # get the referenced expression in order to evaluate it
    db_1row context_info {
        select when_prop_val_is_set_xml
        from imsld_complete_actsi
        where item_id = :complete_act_item_id
        and content_revision__is_live(complete_act_id) = 't'
    }
    set user_id [ad_conn user_id]
    dom parse $when_prop_val_is_set_xml document
    $document documentElement when_prop_val_is_set_root
    set wpv_is_node [$when_prop_val_is_set_root childNodes]
    
    set equal_value_p 0
    # get the property value
    set property_ref [$wpv_is_node selectNodes {*[local-name()='property-ref']}]
    set property_value [imsld::runtime::property::property_value_get -run_id $run_id -user_id $user_id -identifier [$property_ref getAttribute {ref}]]

    # get the value of the referenced exression
    set propertyvalueNode [$wpv_is_node selectNodes {*[local-name()='property-value']}] 
    
    if { [llength $propertyvalueNode] } {
        set propertyvalueChildNode [$propertyvalueNode childNodes]
        set nodeType [$propertyvalueChildNode nodeType]
        switch --  $nodeType {
            {ELEMENT_NODE} {
                switch -- [$propertyvalueChildNode localName] {
                    {calculate} {
                        set expression_value [imsld::expression::eval -run_id $run_id -expression [$propertyvalueChildNode childNodes]]
                    }
                    {property-ref} {
                        set expression_value [imsld::runtime::property::property_value_get -run_id $run_id -user_id $user_id -identifier [$propertyvalueChildNode getAttribute {ref}]]
                    }
                }
            }
            {TEXT_NODE} {
                set expression_value [$propertyvalueNode text]
            }
        }
        
        if { [string eq $property_value $expression_value] } {
            set equal_value_p 1
        }
        
    } else {
        # there is no associated value, the activity is completed
        set equal_value_p 1
    }
    
    if { $equal_value_p } {
        # the values are the same, mark the referenced activity as completed
        # 1. identify what kind of activiy we must mark as finished.
        #    it can be a support activity, learning activity, act or play
        db_1row get_extra_info {
            select imsld_id
            from imsld_runs
            where run_id = :run_id
        }

        if { [db_0or1row learning_activity_p {
            select 'learning' as activity_type,
            item_id as activity_item_id,
            activity_id
            from imsld_learning_activitiesi
            where complete_act_id = :complete_act_item_id
            and content_revision__is_live(activity_id) = 't'
        }] } {
            # mark the act completed for all the users in the run
            set role_part_id_list [imsld::get_role_part_from_activity -activity_type learning -leaf_id $activity_item_id]

            set users_in_run [db_list get_users_in_run {
                select gmm.member_id 
                from group_member_map gmm,
                imsld_run_users_group_ext iruge, 
                acs_rels ar1 
                where iruge.run_id=:run_id
                and ar1.object_id_two=iruge.group_id 
                and ar1.object_id_one=gmm.group_id 
                group by member_id
            }]
            foreach user $users_in_run {
                foreach role_part_id $role_part_id_list {
                    db_1row context_info {
                        select acts.act_id,
                        plays.play_id
                        from imsld_actsi acts, imsld_playsi plays, imsld_role_parts rp
                        where rp.role_part_id = :role_part_id
                        and rp.act_id = acts.item_id
                        and acts.play_id = plays.item_id
                    }
                    imsld::finish_component_element -imsld_id $imsld_id  \
                        -run_id $run_id \
                        -play_id $play_id \
                        -act_id $act_id \
                        -role_part_id $role_part_id \
                        -element_id $activity_id \
                        -type learning \
                        -code_call
                }
            }
        }
        if { [db_0or1row support_activity_p {
            select 'support' as activity_type,
            item_id as activity_item_id,
            activity_id
            from imsld_support_activitiesi
            where complete_act_id = :complete_act_item_id
            and content_revision__is_live(activity_id) = 't'
        }] } {
            # mark the act completed for all the users in the run
            set role_part_id_list [imsld::get_role_part_from_activity -activity_type learning -leaf_id $activity_item_id]

            set users_in_run [db_list get_users_in_run {
                select gmm.member_id 
                from group_member_map gmm,
                imsld_run_users_group_ext iruge, 
                acs_rels ar1 
                where iruge.run_id=:run_id
                and ar1.object_id_two=iruge.group_id 
                and ar1.object_id_one=gmm.group_id 
                group by member_id
            }]
            foreach user $users_in_run {
                foreach role_part_id $role_part_id_list {
                    db_1row context_info {
                        select acts.act_id,
                        plays.play_id
                        from imsld_actsi acts, imsld_playsi plays, imsld_role_parts rp
                        where rp.role_part_id = :role_part_id
                        and rp.act_id = acts.item_id
                        and acts.play_id = plays.item_id
                    }
                    imsld::finish_component_element -imsld_id $imsld_id  \
                        -run_id $run_id \
                        -play_id $play_id \
                        -act_id $act_id \
                        -role_part_id $role_part_id \
                        -element_id $activity_id \
                        -type learning \
                        -code_call
                }
            }
        }
        if { [db_0or1row act_activity_p {
            select 'act' as activity_type,
            ia.act_id,
            ip.play_id
            from imsld_acts ia, imsld_playsi ip
            where ia.complete_act_id = :complete_act_item_id
            and content_revision__is_live(ia.act_id) = 't'
            and ia.play_id = ip.item_id
        }] } {
            # mark the act completed for all the users in the run
            set users_in_run [db_list get_users_in_run {
                select gmm.member_id 
                from group_member_map gmm,
                imsld_run_users_group_ext iruge, 
                acs_rels ar1 
                where iruge.run_id=:run_id
                and ar1.object_id_two=iruge.group_id 
                and ar1.object_id_one=gmm.group_id 
                group by member_id
            }]
            foreach user $users_in_run {
                if { [imsld::user_participate_p -run_id $run_id -act_id $act_id -user_id $user] } {
                    imsld::mark_act_finished -act_id $act_id \
                        -play_id $play_id \
                        -imsld_id $imsld_id \
                        -run_id $run_id \
                        -user_id $user
                }
            }
        }
        if { [db_0or1row play_p {
            select 'play' as activity_type,
            play_id
            from imsld_plays
            where complete_act_id = :complete_act_item_id
            and content_revision__is_live(play_id) = 't'
        }] } {
            # mark the act completed for all the users in the run
            set users_in_run [db_list get_users_in_run {
                select gmm.member_id 
                from group_member_map gmm,
                imsld_run_users_group_ext iruge, 
                acs_rels ar1 
                where iruge.run_id=:run_id
                and ar1.object_id_two=iruge.group_id 
                and ar1.object_id_one=gmm.group_id 
                group by member_id
            }]
            foreach user $users_in_run {
                imsld::mark_play_finished -play_id $play_id \
                    -imsld_id $imsld_id \
                    -run_id $run_id \
                    -user_id $user
            }
        }
    }
}

ad_proc -public imsld::expression::eval {
    -run_id
    -expression
    -user_id
} {
} {
    if {![info exist user_id]} {
        set user_id [ad_conn user_id]
    }
    foreach expressionNode $expression {
        switch -- [$expressionNode localName] {
            {complete} {
                set activityNode [$expressionNode childNodes] 
                switch -- [$activityNode localName] {
                    {learning-activity-ref} {
                        set la_ref [$activityNode getAttribute {ref}]
                        db_1row get_la_id {
                            select ila.activity_id as la_id,
                            iii.imsld_id as imsld_id
                            from imsld_learning_activities ila, 
                            imsld_imsldsi iii, 
                            imsld_componentsi ici, 
                            imsld_runs ir 
                            where ir.run_id=:run_id and 
                            ir.imsld_id=iii.imsld_id and 
                            iii.item_id=ici.imsld_id and 
                            ici.item_id=ila.component_id 
                            and ila.identifier=:la_ref
                        }
                        set return_value [db_0or1row la_finished_p {
                                                                   select 1 
                                                                   from imsld_status_user
                                                                   where status='finished' 
                                                                         and related_id=:la_id 
                                                                         and user_id=:user_id
                                                                         and run_id=:run_id
                        }]
                    }
                    {support-activity-ref} {
                        set sa_ref [$activityNode getAttribute {ref}]
                        db_1row get_sa_id {
                            select isa.activity_id as sa_id, 
                            iii.imsld_id as imsld_id,
                            ir.run_id as run_id
                            from imsld_support_activities isa, 
                            imsld_imsldsi iii, 
                            imsld_componentsi ici, 
                            imsld_runs ir 
                            where ir.run_id=:run_id and 
                            ir.imsld_id=iii.imsld_id and 
                            iii.item_id=ici.imsld_id and 
                            ici.item_id=isa.component_id and 
                            isa.identifier=:sa_ref 
                        }
                        set return_value [db_0or1row la_finished_p {
                                                                   select 1 
                                                                   from imsld_status_user
                                                                   where status='finished' 
                                                                         and related_id=:sa_id 
                                                                         and user_id=:user_id
                                                                         and run_id=:run_id
                        }]
                    }
                    {unit-of-learning-href} {
                        #TODO 
                    }
                    {activity-structure-ref} {
                        se as_ref [$activityNode getAttribute {ref}]
                        db_1row get_as_id {
                            select ias.structure_id as as_id
                            from imsld_activity_structures ias, 
                            imsld_componentsi ici, 
                            imsld_imsldsi iii, 
                            imsld_runs ir 
                            where ir.run_id=:run_id and 
                            ir.imsld_id=iii.imsld_id and 
                            iii.item_id=ici.imsld_id and 
                            ias.component_id=ici.item_id 
                            ias.identifier=:as_ref
                        }
                        set return_value [imsld::structure_finished_p -structure_id $as_id -run_id $run_id -user_id $user_id ]
                    }
                    {act-ref} {
                        set actref [$activityNode getAttribute {ref}]
                        db_1row get_act_id {
                            select iai.act_id as act_id,
                            imi.imsld_id as imsld_id,
                            ipi.play_id as play_id,
                            from imsld_acts iai, 
                            imsld_imsldsi iii, 
                            imsld_playsi ipi, 
                            imsld_methodsi imi, 
                            imsld_runs ir 
                            where ir.run_id=:run_id and 
                            ir.imsld_id=iii.imsld_id and 
                            iii.item_id=imi.imsld_id and 
                            imi.item_id=ipi.method_id and 
                            ipi.item_id=iai.play_id and
                            iai.identifier=:actref
                        }
                        set return_value [imsld:act_finished_p -act_id $act_id -run_id $run_id -user_id $user_id]
                    }
                    {play-ref} {
                        set playref [$activityNode getAttribute {ref}]
                        db_1row get_play_id {
                            select ipi.play_id as play_id
                            iii.imsld_id as imsld_id,
                            from imsld_imsldsi iii, 
                            imsld_plays ipi, 
                            imsld_methodsi imi, 
                            imsld_runs ir 
                            where ir.run_id=:run_id and 
                            ir.imsld_id=iii.imsld_id and 
                            iii.item_id=imi.imsld_id and 
                            imi.item_id=ipi.method_id and 
                            ipi.identifier=:playref                
                        }
                        set return_value [imsld::play_finished_p -play_id $play_id -run_id $run_id -user_id $user_id]
                    }
                }
                return $return_value
            }
            {not} { 
                return [expr ![imsld::expression::eval -run_id $run_id  -user_id $user_id -expression [$expressionNode childNodes]]] 
            }
            {current-datetime} { return [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"] -gmt 1 }
            {datetime-activity-started} {
                # TODO what's the actual way this is enconded in the XML? any examples?
                return TODO
                set activity_ref [$expressionNode getAttribute {ref}]
                #set activity_id [] # need to get the activity_id from the activity_ref
                return [imsld::runtime::date_time_activity_started -run_id $run_id -user_id $user_id -activity_id $activity_id]
            }
            {time-unit-of-learning-started} {
                return [imsld::runtime::time_uol_started -run_id $run_id]
            }
            {no-value} {
                set propertyref [$expressionNode selectNodes {*[local-name()='property-ref']}]
                set propertyvalue [imsld::runtime::property::property_value_get -run_id $run_id -user_id $user_id -identifier [$propertyref getAttribute {ref}]]
                return [empty_string_p $propertyvalue]
            }
            {users-in-role} {
                # TODO Investigate usage in an expression
                set roleref_value [$expressionNode selectNodes {*[local-name()='role-ref']/@ref}]
                set role_id [imsld::roles::get_role_id -ref $roleref_value -run_id $run_id]
                set persons_in_role [imsld::roles::get_users_in_role -run_id $run_id -role_id $role_id]
                
            }
            {less-than} {
                set childs [$expressionNode childNodes]
                set propertyvalue0 [imsld::expression::eval -run_id $run_id  -user_id $user_id -expression [lindex $childs 0]]
                set propertyvalue1 [imsld::expression::eval -run_id $run_id  -user_id $user_id -expression [lindex $childs 1]]
                return [expr {$propertyvalue0 < $propertyvalue1}]
            }
            {greater-than} {
                set childs [$expressionNode childNodes]
                set propertyvalue0 [imsld::expression::eval -run_id $run_id  -user_id $user_id -expression [lindex $childs 0]]
                set propertyvalue1 [imsld::expression::eval -run_id $run_id  -user_id $user_id -expression [lindex $childs 1]]
                return [expr {$propertyvalue0 > $propertyvalue1}]
            }
            {divide} {
                set childs [$expressionNode childNodes]
                return [expr {[imsld::expression::eval -run_id $run_id -expression [lindex $childs 0]] / [imsld::expression::eval -run_id $run_id  -user_id $user_id -expression [lindex $childs 1]]}]
            }
            {multiply} {
                set childs [$expressionNode childNodes]
                set returnvalue 1
                set count 0
                foreach child $childs {
                    set returnvalue [expr {$returnvalue * [imsld::expression::eval -run_id $run_id  -user_id $user_id -expression $child]}]
                    incr count
                }
                set returnvalue [expr { [string eq 0 $count] ? 0 : $returnvalue }]
                return $returnvalue
            }
            {substract} {
                set childs [$expressionNode childNodes]
                return [expr {[imsld::expression::eval -run_id $run_id -expression [lindex $childs 0]] - [imsld::expression::eval -run_id $run_id  -user_id $user_id -expression [lindex $childs 1]]}]
            }
            {sum} {
                set childs [$expressionNode childNodes]
                set returnvalue 0
                foreach child $childs {
                    set returnvalue [expr {$returnvalue + [imsld::expression::eval -run_id $run_id  -user_id $user_id -expression $child]}]
                }
                return $returnvalue
            }
            {or} {
                set childs [$expressionNode childNodes]
                set returnvalue 0
                foreach child $childs {
                    set returnvalue [expr {$returnvalue || [imsld::expression::eval -run_id $run_id  -user_id $user_id -expression $child]}]
                }
                return $returnvalue
            }
            {and} {
                set childs [$expressionNode childNodes]
                set returnvalue 1
                foreach child $childs {
                    set returnvalue [expr {$returnvalue && [imsld::expression::eval -user_id $user_id -run_id $run_id -expression $child]}]
                }
                return $returnvalue
            }
            {is-not} {
                set childs [$expressionNode childNodes]
                set propertyvalue0 [imsld::expression::eval -run_id $run_id  -user_id $user_id -expression [lindex $childs 0]]
                set propertyvalue1 [imsld::expression::eval -run_id $run_id  -user_id $user_id -expression [lindex $childs 1]]
                return [expr {$propertyvalue0 != $propertyvalue1}]
            }
            {is} {
                set childs [$expressionNode childNodes]
                set propertyvalue0 [imsld::expression::eval -run_id $run_id -user_id $user_id -expression [lindex $childs 0]]
                set propertyvalue1 [imsld::expression::eval -run_id $run_id -user_id $user_id -expression [lindex $childs 1]]
                return [expr {$propertyvalue0 == $propertyvalue1}]
            }
            {is-member-of-role} {
                set roleref [$expressionNode getAttribute {ref}]
                set role_id [imsld::roles::get_role_id -ref $roleref -run_id $run_id]
                set users_list [imsld::roles::get_users_in_role -role_id $role_id -run_id $run_id]
                return [ expr { [lsearch $users_list $user_id] > -1} ]
            }
            {property-ref} {
                return [imsld::runtime::property::property_value_get -run_id $run_id -user_id $user_id -identifier [$expressionNode getAttribute {ref}]]
            }
            {property-value} {
                return [$expressionNode text]
            }
        }
    }
}

ad_proc -public imsld::statement::execute {
    -run_id
    -statement
    -user_id
} {
} {
    if {![info exist user_id]} {
	set user_id [ad_conn user_id] 
    }

    foreach executeNode $statement {
        switch -- [$executeNode localName] {
            {show} {
                foreach refNodes [$executeNode childNodes] {
                    switch -- [$refNodes localName] {
                        {class} {
                            set class [$refNodes getAttribute class ""]
                            set title [$refNodes getAttribute title ""]
                            set with_control_p [imsld::parse::get_bool_attribute -node $refNodes -attr_name with-control -default "f"]
                            if { [string eq $class ""] } {
                                
                                # NOTE: according to the spec this attribute may be empty... what to do??
                                ns_log notice "imsld::statement::execute: class ref is empty"
                                continue
                            }
                            imsld::runtime::class::show_hide -class $class -run_id $run_id -title $title \
                                                             -with_control_p $with_control_p -action "show" -user_id $user_id
                        }
                        {environment-ref} {
                            # the environments doesn't have any isvisible attribute, 
                            # so we have to 'show' all the referenced elements
                            imsld::runtime::environment::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "show"
                        }
                        {activity-structure-ref} {
                            imsld::runtime::activity_structure::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "show"
                        }
                        {unit-of-learning-href} {
                            # NOT IMPLEMENTED: noop
                        }
                        {item-ref} {
                            imsld::runtime::isvisible::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "show" -user_id $user_id
                        }
                        {learning-activity-ref} {
                            imsld::runtime::isvisible::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "show" -user_id $user_id
                        }
                        {support-activity-ref} {
                            imsld::runtime::isvisible::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "show" -user_id $user_id
                        }
                        {play-ref} {
                            imsld::runtime::isvisible::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "show" -user_id $user_id
                        }
                    }
                }
            }
            {hide} {
                foreach refNodes [$executeNode childNodes] {
                    switch -- [$refNodes localName] {
                        {class} {
                            set class [$refNodes getAttribute class ""]
                            set title [$refNodes getAttribute title ""]
                            set with_control_p [imsld::parse::get_bool_attribute -node $refNodes -attr_name with-control -default "f"]
                            if { [string eq $class ""] } {
                                
                                # NOTE: according to the spec this attribute may be empty... what to do??
                                ns_log notice "imsld::statement::execute: class ref is empty"
                                continue
                            }
                            imsld::runtime::class::show_hide -class $class -run_id $run_id -title $title \
                                                             -with_control_p $with_control_p -action "hide" -user_id $user_id
                        }
                        {environment-ref} {
                            # the environments doesn't have any isvisible attribute, 
                            # so we have to 'hide' all the referenced elements
                            imsld::runtime::environment::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "hide"
                        }
                        {activity-structure-ref} {
                            imsld::runtime::activity_structure::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "hide"
                        }
                        {unit-of-learning-href} {
                            # NOT IMPLEMENTED: noop
                        }
                        {item-ref} {
                            imsld::runtime::isvisible::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "hide" -user_id $user_id
                        }
                        {learning-activity-ref} {
                            imsld::runtime::isvisible::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "hide" -user_id $user_id
                        }
                        {support-activity-ref} {
                            imsld::runtime::isvisible::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "hide" -user_id $user_id
                        }
                        {play-ref} {
                            imsld::runtime::isvisible::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "hide" -user_id $user_id
                        }
                    }
                }
            }
            {change-property-value} {
                set propertyref [$executeNode selectNodes {*[local-name()='property-ref']}]
                set propertyvalueNode [$executeNode selectNodes {*[local-name()='property-value']}] 
                set propertyvalueChildNode [$propertyvalueNode childNodes]
                set nodeType [$propertyvalueChildNode nodeType]
                switch --  $nodeType {
                    {ELEMENT_NODE} {
                        switch -- [$propertyvalueChildNode localName] {
                            {calculate} {
                                set propertyValue [imsld::expression::eval -run_id $run_id  -user_id $user_id -expression [$propertyvalueChildNode childNodes]]
                            }
                            {property-ref} {
                                set propertyValue [imsld::runtime::property::property_value_get -run_id $run_id -user_id $user_id -identifier [$propertyvalueChildNode getAttribute {ref}]]
                            }
                            
                        }
                    }
                    {TEXT_NODE} {
                        set propertyValue [$propertyvalueNode text]
                    }
                }
                imsld::runtime::property::property_value_set -run_id $run_id -user_id $user_id -identifier [$propertyref getAttribute {ref}] -value $propertyValue
            }
            {notification} {
                set activity_id ""
                set subjectValue ""
                set notified_users_list [list]
                set subjectNode [$executeNode selectNodes {*[local-name()='subject']}]
                if { [llength $subjectNode] } {
                    set subjectValue [$subjectNode text]
                }

                set larefNode [$executeNode selectNodes {*[local-name()='learning-activity-ref']}] 
                if { [llength $larefNode] } {
                    set larefValue [$larefNode getAttribute ref ""]
                    set activityIdentifier $larefValue
                }

                set sarefNode [$executeNode selectNodes {*[local-name()='support-activity-ref']}] 
                if { [llength $sarefNode] } {
                    set sarefValue [$sarefNode getAttribute ref ""]
                    set activityIdentifier $sarefValue
                }
                
                if { [info exists activityIdentifier] } {
                    set activity_id [db_string get_activity_id {
                        select owner_id
                        from imsld_attribute_instances
                        where identifier = :activityIdentifier
                        and run_id = :run_id
                        and user_id = :user_id
                    }]
                }

                foreach emailDataNode [$executeNode selectNodes {*[local-name()='email-data']}] {

                    set emailPropertyRef [$emailDataNode getAttribute email-property-ref ""]
                    set usernamePropertyRef [$emailDataNode getAttribute username-property-ref ""]
                    set roleRef [[$emailDataNode selectNodes {*[local-name()='role-ref']}] getAttribute ref ""]
                    set username ""
                    set email_address ""
                    
                    if { ![empty_string_p $usernamePropertyRef] } {
                        # get the username proprty value
                        # NOTE: there is no specification for the format of the email property value
                        #       so we assume it is a single username
                        set username [imsld::runtime::property::property_value_get -run_id $run_id -user_id $user_id -identifier $usernamePropertyRef]
                    }

                    if { ![empty_string_p $emailPropertyRef] } {
                        # get the email proprty value
                        # NOTE: there is no specification for the format of the email property value
                        #       so we assume it is a single email address.
                        #       we also send the notificaiton to the rest of the role members
                        set email_address [imsld::runtime::property::property_value_get -run_id $run_id -user_id $user_id -identifier $emailPropertyRef]
                    }
                    
                    db_1row get_context_info {
                        select role_id, ii.imsld_id
                        from imsld_roles ir, imsld_componentsi ic, imsld_imsldsi ii, imsld_runs run
                        where ir.identifier = :roleRef
                        and ir.component_id = ic.item_id
                        and ic.imsld_id = ii.item_id
                        and ii.imsld_id = run.imsld_id
                        and run.run_id = :run_id
                    }
                    
                    set notified_users_list [imsld::do_notification -imsld_id $imsld_id \
                                                 -run_id $run_id \
                                                 -subject $subjectValue \
                                                 -activity_id $activity_id \
                                                 -username $username \
                                                 -email_address $email_address \
                                                 -role_id $role_id \
                                                 -user_id $user_id \
                                                 -notified_users_list $notified_users_list]
                }
            }
        }
    }
}
