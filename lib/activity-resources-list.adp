<if @has_items@>
    <ul>
      <multiple name="resources">

        <include src="activity-resource"
        resource_item_id="@resources.resource_item_id@" run_id="@run_id@"
        li_mode_p="t" monitor_p="@monitor_p@" />

      </multiple>
    </ul>
</if>