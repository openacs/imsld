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
	        foreach activityNode [$expressionNode childNodes] {
	            # TODO
		    return 1
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
        switch -- [$executeNode localName] {
            {show} {}
            {hide} {}
            {change-property-value} {
	        set propertyref [$executeNode selectNodes {*[local-name()='property-ref']}]
	        set propertyvalue [[$executeNode selectNodes {*[local-name()='property-value']}] nodeValue]
	        imsld::runtime::property::property_value_set -run_id $run_id -user_id $user_id -identifier [$propertyref getAttribute {ref}] -value $propertyvalue
	    }
            {notification} {}
	}
    }
}
