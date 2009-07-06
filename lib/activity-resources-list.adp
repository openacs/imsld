<if @resources:rowcount@ gt 1 or @monitor_p@ true>
    <ul>
      <multiple name="resources">

        <include src="activity-resource"
        resource_item_id="@resources.resource_item_id@" run_id="@run_id@"
        li_mode_p="t" monitor_p="@monitor_p@" activity_id="@activity_id@" />

      </multiple>
    </ul>
</if>
