ad_page_contract {
} {
    send_mail_id
    run_id
}


set page_title "Groups of receivers"
set context {}
set community_id [dotlrn_community::get_community_id]


db_multirow -extend {send_mail_url} all_email_data get_all_email_data {} {
    set send_mail_url [export_vars -base imsld-sendmail-2 {{recipients $recipients} {role_recipient $group_recipient} {run_id $run_id}}]
}
