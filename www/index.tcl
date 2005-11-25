ad_page_contract {
}

set page_title index
set context {}
set community_id [dotlrn_community::get_community_id]

db_multirow imslds_in_class get_manifests {
    select cr3.item_id as imsld_id,
    coalesce(imsld.title, imsld.identifier) as imsld_title
    from acs_rels ar, cr_items cr1, cr_items cr2, cr_items cr3, imsld_cp_manifests icm, imsld_cp_organizations ico, imsld_imsldsi imsld 
    where ar.object_id_one = :community_id
    and ar.rel_type = 'imsld_community_manifest_rel'
    and ar.object_id_two = cr1.item_id
    and cr1.live_revision = icm.manifest_id
    and ico.manifest_id = cr1.item_id
    and imsld.organization_id = cr2.item_id
    and cr2.live_revision = ico.organization_id
    and cr3.live_revision = imsld.imsld_id
}
