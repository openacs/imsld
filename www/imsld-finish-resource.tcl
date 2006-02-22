ad_page_contract {
    @author lfuente@it.uc3m.es
    @creation-date Jan 2006
} {
    file_url
    resource_item_id
}

# fedback nor assessment has to be marked as finished
if { [db_0or1row not_fedbk_nor_assmnt { 
    select icr.resource_id
    from acs_rels ar,
    imsld_cp_resourcesi icr
    where ar.rel_type != 'imsld_feedback_rel'
    and icr.item_id = ar.object_id_two
    and ar.object_id_two = :resource_item_id
    and icr.type != 'imsqti_xmlv1p0'
    limit 1
}] } {
    imsld::finish_resource -resource_id $resource_id
}

ad_returnredirect $file_url
