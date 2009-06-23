ad_page_contract {
    This is only for redirection
} -query {
    {url ""}
    run_id
    gservice_id
    user_id:optional
}

if { [string eq $url ""] } {
    if { ![info exists user_id] } {
       set user_id [ad_conn user_id]
    }

    db_1row get_url {
        select spreadsheet_url as url
        from imsld_gsi_p_gspread_usersmap
        where run_id=:run_id and user_id=:user_id
    }
}
ad_returnredirect $url 
