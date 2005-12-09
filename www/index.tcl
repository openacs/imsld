ad_page_contract {
}

set page_title index
set context {}
set community_id [dotlrn_community::get_community_id]

set cr_root_folder_id [imsld::cr::ger_root_folder -community_id $community_id]

db_multirow imslds_in_class get_manifests {
    select cr3.item_id as imsld_id,
    coalesce(imsld.title, imsld.identifier) as imsld_title
    from cr_items cr1, cr_items cr2, cr_items cr3, cr_items cr4,
    imsld_cp_manifests icm, imsld_cp_organizations ico, imsld_imsldsi imsld 
    where cr1.live_revision = icm.manifest_id
    and cr1.parent_id = cr4.item_id
    and cr4.parent_id = :cr_root_folder_id
    and ico.manifest_id = cr1.item_id
    and imsld.organization_id = cr2.item_id
    and cr2.live_revision = ico.organization_id
    and cr3.live_revision = imsld.imsld_id
} {
}
