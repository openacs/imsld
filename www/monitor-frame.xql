<?xml version="1.0"?>
<queryset>

    <fullquery name="monitor_service_info">
      <querytext>
        select ims.title as monitor_service_title,
        ims.monitor_id,
        ims.item_id as monitor_item_id,
        ims.self_p,
        cr2.live_revision as role_id,
        cr.live_revision as imsld_item_id
        from imsld_monitor_servicesi ims, cr_items cr, cr_items cr2
        where ims.monitor_id = :monitor_id
        and cr.item_id = ims.imsld_item_id
        and content_revision__is_live(cr.live_revision) = 't'
        and ims.role_id = cr2.item_id    
      </querytext>
	</fullquery>

    <fullquery name="monitor_associated_item">
      <querytext>

        select cpr.resource_id,
        cpr.item_id as resource_item_id,
        cpr.type as resource_type
        from imsld_cp_resourcesi cpr, imsld_itemsi ii,
        acs_rels ar
        where ar.object_id_one = ii.item_id
        and ar.object_id_two = cpr.item_id
        and content_revision__is_live(cpr.resource_id) = 't'
        and ii.imsld_item_id = :imsld_item_id
      </querytext>
	</fullquery>

    
</queryset>
