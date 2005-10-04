ad_page_contract {
}

set page_title index
set context {}
set community_id 2148

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
} {
    ns_log notice "vamos!!!!! \n"
}

#     set next_activity get_next_activity
#     display ismld_name
#     display copmleted activities
#     display next activity with finished link and with link to the activity: if it is an activity structure?
#                             the link finished will just add an entry to the status table 
#                             environments?
#                             si es la primera vez, redirigir a un javascript q marque la entrada para contar el tiempo en time_to_complete
#                            manejar completadas, faltante y nombre con listas y mejorar despliegue!

