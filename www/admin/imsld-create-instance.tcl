# /packages/imsld/www/admin/imsld-create-instance.tcl

ad_page_contract {
    Create a instance of a role
    
    @author lfuente@it.uc3m.es
    @creation-date Mar 2006
} {
    {user_id:multiple "0"}
    role
    imsld_id
    parent_group_id:optional
}

db_1row get_imsld_role_info {}
set number_of_groups [llength [db_list get_related_groups {}]]

set return_url [export_vars -base imsld-admin-roles {{role $role} {imsld_id $imsld_id} }]

if { !([string eq $number_of_groups "0"] || [string eq $create_new_p  "t"] ) } {

        set mensaje "<p>Current Unit of Learning does not allow creation of multiple instances of this role.</p>
            <a href=\"$return_url\">Go back</a>"
    ad_return_complaint 1 $mensaje
    ad_script_abort
}

if {[info exist parent_group_id] } {
    set new_instance [imsld::roles::create_instance -role_id $role -parent_group_id $parent_group_id]
    ad_returnredirect [export_vars -base imsld-admin-roles {{role $role} {imsld_id $imsld_id} {group_instance $new_instance}}]
} elseif { ![db_0or1row has_role_parent_p {}] } {
    set new_instance [imsld::roles::create_instance -role_id $role]
    ad_returnredirect [export_vars -base imsld-admin-roles {{role $role} {imsld_id $imsld_id} {group_instance $new_instance}}]
} else {
    set flag on
    template::list::create \
        -name possible_parents \
        -multirow possible_parents \
        -elements {
            parent_name {
                label "Parent role instances"
                link_url_col link_to 
            }
        }
    db_multirow -extend {link_to} possible_parents get_possible_parents_list {} {
        set link_to [export_vars -base imsld-create-instance {role imsld_id {parent_group_id $parent_id}}]
    }
}

