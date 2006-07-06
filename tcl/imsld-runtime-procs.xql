<?xml version="1.0"?>
<queryset>

    <fullquery name="imsld::runtime::property::instance_value_set.update_instance_value">
        <querytext>
            update imsld_property_instances
            set value = :value
            where instance_id = :instance_id
        </querytext>
	</fullquery>

    <fullquery name="imsld::runtime::time_uol_started.date_time">
        <querytext>
            select status_date
            from imsld_runs
            where run_id = :run_id
            and status = 'started'
        </querytext>
	</fullquery>

    <fullquery name="imsld::runtime::date_time_activity_started.date_time">
        <querytext>
            select status_date
            from imsld_status_user
            where run_id = :run_id
            and user_id = :user_id
            and status = 'started'
        </querytext>
	</fullquery>

    <fullquery name="imsld::runtime::class::show_hide.set_class_shown_hidden">
        <querytext>
            update imsld_attribute_instances
            set is_visible_p = :is_visible_p,
            with_control_p = :with_control_p,
            title = :title
            where run_id = :run_id
              and identifier = :class
              and type = 'class'
        </querytext>
	</fullquery>

    <fullquery name="imsld::runtime::isvisible::show_hide.set_isvisible_shown">
        <querytext>
            update imsld_attribute_instances
            set is_visible_p = :is_visible_p
            where run_id = :run_id
              and identifier = :identifier
              and type = 'isvisible'
        </querytext>
	</fullquery>

</queryset>
