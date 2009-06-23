ad_library {
    Procedures of the xowiki gsi plugins.
    
    @creation-date Dic 2008
    @author lfuente@it.uc3m.es
}

namespace eval imsld {}
namespace eval imsld::gsi {}

#each plugin with its own namespace. All plugins has the same public procedures.
namespace eval imsld::gsi::p_xowiki {}

#procedures to implement
#send_check_request
#

ad_proc -public imsld::gsi::p_xowiki::send_check_request {
   functions
   permissions
} {
    
} {
    #fixme: this must be done with real requests to the service
    return [list \
                   [list \
                            [list "deploy" {}] \
                            [list "close" {}]] \
                   [list \
                            [list "write" "contribution" "user"] \
                            [list "read" "context" {}] ] ]
}


ad_proc -public imsld::gsi::p_xowiki::get_external_credentials {
    -user_id
    -run_id
} {
    Returns the external credentials for a given user, in a given instance
} {
    return [db_string get_credentials {
               SELECT external_credentials 
               FROM imsld_gsi_p_xow_usersmap
               WHERE user_id=:user_id and run_id=:run_id
           } -default "" ]
}


ad_proc -public imsld::gsi::p_xowiki::get_external_user {
    -user_id
    -run_id
} {
    Returns the external username for a given user, in a given instance
} {
    return [db_string get_username {
               SELECT external_user 
               FROM imsld_gsi_p_xow_usersmap
               WHERE user_id=:user_id and run_id=:run_id
           } -default "" ]
}

ad_proc -public imsld::gsi::p_xowiki::initialize_user {
    -user_id 
    -run_id
} {
   Initializes a user in the external service mapping table. That is, insert an unmapped row 
} {
    db_dml isert_user {
        INSERT INTO imsld_gsi_p_xow_usersmap VALUES (:user_id,:run_id,'void','void')
    }
}

ad_proc -public imsld::gsi::p_xowiki::map_user {
    -user_id
    -run_id
    -external_user
    -external_credentials
} {
    Do de mapping between a .LRN user and the externall user
} {
    if {![info exists external_user] && ![info exists external_credentials]} {
        return 
    } elseif {[info exists external_user] && ![info exists external_credentials]} {
        db_dml map_user {
            UPDATE imsld_gsi_p_xow_usersmap
            SET external_user=:external_user
            WHERE user_id=:user_id and run_id=:run_id
        }
    } elseif {![info exists external_user] && [info exists external_credentials]} {
        db_dml map_user {
            UPDATE imsld_gsi_p_xow_usersmap
            SET external_credentials=:external_credentials
            WHERE user_id=:user_id and run_id=:run_id
        }
    } else {
        db_dml map_user {
            UPDATE imsld_gsi_p_xow_usersmap
            SET external_user=:external_user, 
                external_credentials=:external_credentials
            WHERE user_id=:user_id and run_id=:run_id
        }
    }
}


ad_proc -public imsld::gsi::p_xowiki::request_configured_instance {
    -user_id
    -run_id
    -gservice_id
    -external_user
    -external_credentials
} {
    Retrieves a URL to access a configured instance of a given user
} {
    set all_urls [list]
    lappend all_urls "www.google.es"
    lappend all_urls "gmail.com"
    return all_urls
}

