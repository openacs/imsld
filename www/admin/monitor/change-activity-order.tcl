# 

ad_page_contract {
    
    Change activity order within a structure activity
    
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2008-10-31
    @cvs-id $Id$
} {
    run_id:integer,notnull
    item_id:integer,notnull
    sort_order:integer,notnull
    dir:integer,notnull
} -properties {
} -validate {
} -errors {
}

if { $dir < 0 } {
    set dir -1
} else {
    set dir 1
}

set new_order [expr {$sort_order + $dir}]

array set rel_table [list imsld_as_la_rel imsld_as_la_rels imsld_as_sa_rel imsld_as_sa_rels imsld_as_as_rel imsld_as_as_rels]

# get the rel_id and activity_structure_id so we can update the
# sort_order value of the item
db_1row select_rel {
    select ar.rel_id, ar.object_id_one as structure_id, ar.rel_type
    from acs_rels ar,
    (select * from imsld_as_la_rels union select * from imsld_as_sa_rels union
     select * from imsld_as_as_rels) as ir
    where ar.rel_id = ir.rel_id
    and ar.object_id_two = :item_id
}

db_dml update_order "
    update $rel_table($rel_type)
    set sort_order = $new_order
    where rel_id = $rel_id
"

# get the rel_id for the item before/after so we can update the
# its sort_order value
if {[db_0or1row select_rel {
    select ar.rel_id, ar.object_id_one as structure_id, ar.rel_type
    from acs_rels ar,
    (select * from imsld_as_la_rels union select * from imsld_as_sa_rels union
     select * from imsld_as_as_rels) as ir
    where ar.rel_id = ir.rel_id
    and ar.object_id_one = :structure_id
    and ar.object_id_two != :item_id
    and ir.sort_order = :new_order
}]} {
    db_dml update_order "
      update $rel_table($rel_type)
      set sort_order = $sort_order
      where rel_id = $rel_id
  "
}

ad_returnredirect [export_vars -base monitor-tree {run_id}]
