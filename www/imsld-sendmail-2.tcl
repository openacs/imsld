ad_page_contract {
} {
    recipients
    role_recipient
    run_id
}

set users_list [imsld::roles::get_mail_recipients -role_destination_ref $role_recipient -run_id $run_id]
set users_list [lindex $users_list 0]

if {[string eq $recipients all-in-role]} {
    #all the role members: get the receipients, redirects and that's it

    
    ad_returnredirect [export_vars -base ../spam {{recipients:multiple $users_list} {referer one-community-admin}}]
    ad_script_abort
} else {
    #chosse among members the receiptients. use a template::list
    set page_title "Role members"
    set context {}
    set bulk_actions "{Compose mail} {../spam} {Send mail to selected members}"
    
    template::list::create \
        -name find_recipients \
        -multirow find_recipients \
        -key recipients \
        -elements {
            user_id {             
                label {Role member name}
                display_col full_name
            }
        } \
        -bulk_actions "$bulk_actions" \
        -bulk_action_export_vars "{referer one-community}"

    db_multirow -extend { recipients full_name} find_recipients get_recipients_info {} {
        set recipients $user_id
        set full_name [concat $first_names $last_name]
    }
}

