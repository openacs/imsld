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

    <fullquery name="">
        <querytext>
        </querytext>
	</fullquery>

</queryset>
