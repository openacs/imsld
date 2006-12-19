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

    # clean rels
    imsld::uninstall::delete_rels
    imsld::uninstall::delete_ext_rels

    
    #clean groups
    imsld::uninstall::delete_group_types

    
    # clean the cr
    imsld::uninstall::empty_content_repository

    return 1
}

