# /packages/imsld/www/admin/imsld-delete.tcl

ad_page_contract {

	Deletes a imsld after confirmation

    @author jopez@inv.it.uc3m.es
    @creation-date Nov 2005
    @cvs-id $Id$

} {
	imsld_id:integer,notnull
	{return_url "index"}
}

set user_id [ad_conn user_id]

set page_title "Delete IMS LD"

set context [list [list "index" "Admin IMS LD"] "Delete IMS LD"]

db_1row get_grade_info {
    select title as imsld_title
    from imsld_imsldsi
	where imsld_id = :imsld_id
}

set export_vars [export_form_vars imsld_id return_url]

ad_return_template
