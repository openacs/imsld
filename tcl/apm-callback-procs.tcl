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
    ismld::install::init_rels
}

ad_proc -public imsld::apm_callback::before_uninstall {  
} { 
    Proc calls and tasks needed to be donde before the uninstallation of the imsld package.
} { 
    # clean rels
    imsld::uninstall::delete_rels

    # clean the cr
    imsld::uninstall::empty_content_repository
}

