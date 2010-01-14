# /packages/imsld/tcl/apm-callback-procs.tcl

ad_library {
    Callback library for the apm
    
    @creation-date Jul 2005
    @author jopez@inv.it.uc3m.es
    @cvs-id $Id$
}

namespace eval imsld {}
namespace eval imsld::apm_callback {}

ad_proc -public imsld::apm_callback::after_install {  
} { 
    Proc calls and tasks needed to be donde after the installation of the imsld package.
} { 
    # initalize the cr
    imsld::install::init_content_repository
    
    # create default relationships
    imsld::install::init_rels

    imsld::install::create_group_types

    # create default relationships with non IMS-LD objects
    imsld::install::init_ext_rels

    #create the GSI model
    imsld::gsi::install::do_install

    return 1
}

ad_proc -public imsld::apm_callback::before_uninstantiate {
    -package_id:required
} {
    task that must be done before uninstance the imsld package
} { 
    imsld::drop_imsld_package -object_id $package_id
}

ad_proc -public imsld::apm_callback::before_unmount {
    -node_id:required
    -package_id:required
} {
    task that must be done before unmount the imsld package 
} { 


}

ad_proc -public imsld::apm_callback::before_uninstall {  
} { 
    Proc calls and tasks needed to be donde before the uninstallation of the imsld package.
} { 
    #clean the GSI model
    imsld::gsi::uninstall::do_uninstall
    
    # clean rels
    imsld::uninstall::delete_rels
    imsld::uninstall::delete_ext_rels

    
    #clean groups
    imsld::uninstall::delete_group_types

    
    # clean the cr
    imsld::uninstall::empty_content_repository

    return 1
}


ad_proc -public imsld::apm_callback::after_upgrade {
    -from_version_name:required
    -to_version_name:required
} {
    Upgrade script for the IMS-LD package

    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2008-06-16
    
    @return 
    
    @error 
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            1.3d 1.4d {
                content::type::attribute::new -content_type imsld_complete_act \
                    -attribute_name time_string -datatype string \
                    -pretty_name "#imsld.Time_String#" -column_spec "varchar(30)"
            }
            1.5d 1.6d {
                content::type::attribute::new -content_type imsld_imsld \
                    -attribute_name resource_handler -datatype string \
                    -pretty_name "#imsld.Resource_Handler#" -column_spec "varchar(100)"
            }
            1.7d 1.8d {
                imsld::gsi::install::do_install
            }
            2.0d 2.0 {
                if { [imsld::global_folder_id] eq "" } {
                    imsld::install::create_global_folder
                }
            }
        }

}
