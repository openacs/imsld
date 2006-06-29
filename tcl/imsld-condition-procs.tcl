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

ad_proc -public imsld::condition::execute {
    -run_id
    -condition
} {
} {
    dom parse $condition document
    $document documentElement root

    set ifNodes [$root selectNodes {*[local-name()='if']}]
    set thenNodes [$root selectNodes {*[local-name()='then']}]
    set elseNodes [$root selectNodes {*[local-name()='else']}]

    foreach ifNode $ifNodes {
        if {[imsld::expression::eval -run_id $run_id -expression [$ifNode childNodes]]} {
	    foreach thenNode $thenNodes {
	        imsld::statement::execute -run_id $run_id -statement [$thenNode childNodes]
	    }
	} else {
	    foreach elseNode $elseNodes {
            #an else node may contain an expression or another if_then_else
            if { [string eq [ [$elseNode selectNodes {*[position()=1] } ] localName] "if" ] } {
                imsld::condition::execute -run_id $run_id -condition $elseNode
            } else {
                imsld::statement::execute -run_id $run_id -statement [$elseNode childNodes]
            }
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

		    return 1

	        set activityNode [$expressionNode childNodes] 
            switch -- [$activityNode localName] {
            {learning-activity-ref} {
                                     set la_ref [$activityNode getAttribute {ref}]
                                     db_1row get_la_id {
                                                    select ila.activity_id as la_id 
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
                                    imsld::finish_component_element -imsld_id $imsld_id \
                                                                    -run_id $run_id \
                                                                    -element_id $la_id \
                                                                    -type learning \
                                                                    -user_id $user_id \
                                                                    -code_call

                                    }
            {support-activity-ref} {
                                   set sa_ref [$activityNode getAttribute {ref}]
                                   db_1row get_sa_id {
                                                     select isa.activity_id as sa_id 
                                                            iii.imsld_id as imsld_id
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
                                     imsld::finish_component_element -imsld_id $imsld_id \
                                                                    -run_id $run_id \
                                                                    -element_id $sa_id \
                                                                    -type support \
                                                                    -user_id $user_id \
                                                                    -code_call
                                      
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
                                    #TODO meter la función finish
                                     }
            {act-ref} {
                       set actref [$activityNode getAttribute {ref}]
                       db_1row get_act_id {
                                          select iai.act_id as act_id
                                                 imi.imsld_id as imsld_id
                                                 ipi.play_id as play_id
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
                      imsld:mark_act_finished -play_id $play_id -imsld_id $imsld_id \
                                              -act_id $act_id -run_id $run_id -user_id $user_id
                      }
            {play-ref} {
                       set playref [$activityNode getAttribute {ref}]
                       db_1row get_play_id {
                                           select ipi.play_id as play_id
                                                  iii.imsld_id as imsld_id
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
                       imsld::mark_play_finished -play_id $play_id -imsld_id $imsld_id \
                                                 -run_id $run_id  -user_id $user_id 
                       }
	        }
	    }
	    {not} { return [expr ![imsld::expression::eval -run_id $run_id -expression $expressionNode]] }
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
	        return [expr {[imsld::expression::eval -run_id $run_id -expression $childs[0]] < [imsld::expression::eval -run_id $run_id -expression $childs[1]]}]
	    }
	    {greater-than} {
	        set childs [$expressionNode childNodes]
	        return [expr {[imsld::expression::eval -run_id $run_id -expression $childs[0]] > [imsld::expression::eval -run_id $run_id -expression $childs[1]]}]
	    }
	    {divide} {
	        set childs [$expressionNode childNodes]
	        return [expr {[imsld::expression::eval -run_id $run_id -expression $childs[0]] / [imsld::expression::eval -run_id $run_id -expression $childs[1]]}]
	    }
	    {multiply} {
	        set childs [$expressionNode childNodes]
		set returnvalue 0
		foreach child $childs {
		    set returnvalue [expr {$returnvalue * [imsld::expression::eval -run_id $run_id -expression $child]}]
		}
	        return $returnvalue
	    }
	    {substract} {
	        set childs [$expressionNode childNodes]
	        return [expr {[imsld::expression::eval -run_id $run_id -expression $childs[0]] - [imsld::expression::eval -run_id $run_id -expression $childs[1]]}]
	    }
	    {sum} {
	        set childs [$expressionNode childNodes]
		set returnvalue 0
		foreach child $childs {
		    set returnvalue [expr {$returnvalue + [imsld::expression::eval -run_id $run_id -expression $child]}]
		}
	        return $returnvalue
	    }
	    {or} {
	        set childs [$expressionNode childNodes]
		set returnvalue 0
		foreach child $childs {
		    set returnvalue [expr {$returnvalue || [imsld::expression::eval -run_id $run_id -expression $child]}]
		}
	        return $returnvalue
	    }
	    {and} {
	        set childs [$expressionNode childNodes]
		set returnvalue 1
		foreach child $childs {
		    set returnvalue [expr {$returnvalue && [imsld::expression::eval -run_id $run_id -expression $child]}]
		}
	        return $returnvalue
	    }
	    {is-not} {
	        set propertyref [$expressionNode selectNodes {*[local-name()='property-ref']}]
	        set propertyvalue0 [imsld::runtime::property::property_value_get -run_id $run_id -user_id $user_id -identifier [$propertyref getAttribute {ref}]]
	        set propertyvalue1 [[$expressionNode selectNodes {*[local-name()='property-value']}] nodeValue]
	        return [expr {$propertyvalue0 != $propertyvalue1}]
	    }
	    {is} {
	        set propertyref [$expressionNode selectNodes {*[local-name()='property-ref']}]
	        set propertyvalue0 [imsld::runtime::property::property_value_get -run_id $run_id -user_id $user_id -identifier [$propertyref getAttribute {ref}]]
	        set propertyvalue1 [[$expressionNode selectNodes {*[local-name()='property-value']}] nodeValue]
	        return [expr {$propertyvalue0 == $propertyvalue1}]
	    }
	    {is-member-of-role} {
            set roleref [$expressionNode getAttribute {ref}]
            set role_id [imsld::roles::get_role_id -ref $roleref -run_id $run_id]
            set users_list [imsld::roles::get_users_in_role -role_id $role_id -run_id $run_id]
            return [ expr { [lsearch $users_list $user_id] > -1} ]
	    }
	}
    }
}

ad_proc -public imsld::statement::execute {
    -run_id
    -statement
} {
} {
    if {![info exist user_id]} {
	set user_id [ad_conn user_id] 
    }

    foreach executeNode $statement {
        switch -- [$executeNode nodeName] {
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
                            imsld::runtime::class::show_hide -class $class -run_id $run_id -title $title -with_control $with_control -action "show"
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
                            imsld::runtime::isvisible::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "show"
                        }
                        {learning-activity-ref} {
                            imsld::runtime::isvisible::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "show"
                        }
                        {support-activity-ref} {
                            imsld::runtime::isvisible::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "show"
                        }
                        {play-ref} {
                            imsld::runtime::isvisible::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "show"
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
                            imsld::runtime::class::show_hide -class $class -run_id $run_id -title $title -with_control $with_control -action "hide"
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
                            imsld::runtime::isvisible::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "hide"
                        }
                        {learning-activity-ref} {
                            imsld::runtime::isvisible::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "hide"
                        }
                        {support-activity-ref} {
                            imsld::runtime::isvisible::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "hide"
                        }
                        {play-ref} {
                            imsld::runtime::isvisible::show_hide -run_id $run_id -identifier [$refNodes getAttribute "ref"] -action "hide"
                        }
                    }
                }
            }
            {change-property-value} {
                set propertyref [$executeNode selectNodes {*[local-name()='property-ref']}]
                set propertyvalue [[$executeNode selectNodes {*[local-name()='property-value']}] nodeValue]
                imsld::runtime::property::property_value_set -run_id $run_id -user_id $user_id -identifier [$propertyref getAttribute {ref}] -value $propertyvalue
            }
        }
        {notification} {}
    }
}
