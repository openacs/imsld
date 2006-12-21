# packages/imsld/www/admin/monitor/run-info.tcl

ad_page_contract {
    
    Displays the run info

    @author jopez@inv.it.uc3m.es
    @creation-date Dic 06
    @cvs-id $Id$
} {
    run_id:integer,notnull
} -properties {
} -validate {
} -errors {
}

db_1row context_info {
    select ir.status,
    to_char(ir.creation_date,'DAY, DD MON YYYY') as creation_date,
    to_char(ir.status_date,'YYYY-MM-DD HH24:MM') as status_date,
    content_item__get_title(ii.item_id) as imsld_title
    from imsld_runs ir, imsld_imsldsi ii
    where ir.run_id = :run_id
    and ir.imsld_id = ii.imsld_id
}


db_1row get_users_in_run {
    select count(distinct(gmm.member_id)) as number_of_members
    from group_member_map gmm,
    imsld_run_users_group_ext iruge, 
    acs_rels ar1 
    where iruge.run_id=:run_id
    and ar1.object_id_two=iruge.group_id 
    and ar1.object_id_one=gmm.group_id 
}