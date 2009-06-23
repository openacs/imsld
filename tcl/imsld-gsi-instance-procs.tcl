# /packages/imsld/tcl/imsld-gsi-procs.tcl

ad_library {
    Procedures for instantiation of gsi namespace.
    
    @creation-date Nov 2008
    @author lfuente@it.uc3m.es
}

namespace eval imsld {}
namespace eval imsld::gsi {}
namespace eval imsld::gsi::instance {}

ad_proc -public imsld::gsi::instance::instantiate_service {
    -component_item_id
    -run_id
    -user_id
} {
    @param component_item_id
    @param run_id
    @param user_id
} {
    db_foreach generic_service {
        select gserv.gsi_service_id,
        coalesce(gserv.is_visible_p, 't') as is_visible_p,
        gserv.identifier
        from imsld_gsi_services gserv, imsld_environmentsi env
        where gserv.environment_id = env.item_id
        and env.component_id = :component_item_id
    } {
        if { ![db_0or1row serv_already_instantiated_p {
            select 1
            from imsld_attribute_instances
            where owner_id = :gsi_service_id
            and run_id = :run_id
            and user_id = :user_id
            and type = 'isvisible'
        }] } { 
            set instance_id [package_exec_plsql -var_list \
                             [list [list instance_id ""] \
                                  [list owner_id $gsi_service_id] \
                                  [list type "isvisible"] \
                                  [list identifier $identifier] \
                                  [list run_id $run_id] \
                                  [list user_id $user_id] \
                                  [list is_visible_p $is_visible_p] \
                                  [list title ""] \
                                  [list with_control_p ""]] \
                             imsld_attribute_instance new]

#            db_dml insert_new_service_instance {
#                INSERT INTO imsld_gsi_serv_instances VALUES (:instance_id, '')
#            }
            if { ![db_0or1row status_already_set {
                select 1 
                from imsld_gsi_service_status
                where owner_id=:gsi_service_id and
                      run_id=:run_id
            }] } {
                set service_status_id [db_nextval acs_object_id_seq]
                #insert a row in imsld_gsi_service_status
                db_dml insert_new_service_status {
                    INSERT 
                    INTO imsld_gsi_service_status 
                    VALUES (:service_status_id,:gsi_service_id,:run_id,'not-configured','',now())
                }
            }
        }
    }
}

