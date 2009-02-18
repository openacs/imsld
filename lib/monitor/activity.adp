<switch @type@>
  <case value="learning">
    <a href="@href@"
      onclick="return(loadContent('@div@'))">
      @activity_title@
    </a>
    <include src="activity-info" type="activity" revision_id="@activity_id@"
      run_id="@run_id@" sort_order="@sort_order@" title="@activity_title@"
      number_elements="@siblings_number@" />
    <include src="../activity-resources-list" activity_item_id="@activity_item_id@"
      run_id="@run_id@" user_id="@user_id@" />
  </case>
  
  <case value="support">
    <a href="@href@"
      onclick="return(loadContent('@div@'))">
      @activity_title@
    </a>
    <include src="activity-info" type="activity" revision_id="@activity_id@"
      run_id="@run_id@" sort_order="@sort_order@" title="@activity_title@"
      number_elements="@siblings_number@" />
    <include src="activity-resources-list" activity_item_id="@activity_item_id@"
      run_id="@run_id@" user_id="@user_id@" />
  </case>
  
  <case value="structure">
    <a href="@href@"
      onclick="return(loadContent('@div@'))">
      @activity_title@
    </a>
    <include src="activity-info" type="activity" revision_id="@activity_id@"
      run_id="@run_id@" sort_order="@sort_order@" title="@activity_title@"
      number_elements="@siblings_number@" />
    <if @referenced_activities:rowcount@>
      <ul>
        <multiple name="referenced_activities">
          <li id="activity_@referenced_activities.r_activity_id@">
            <include src="activity" run_id="@run_id@"
              type="@referenced_activities.activity_type@"
              activity_id="@referenced_activities.r_activity_id@"
              imsld_id="@imsld_id@" play_id="@play_id@" act_id="@act_id@"
              structure_item_id="@structure_item_id@"
              sort_order="@referenced_activities.sort_order@"
              siblings_number="@referenced_activities:rowcount@" />
          </li>
        </multiple>
      </ul>
    </if>
  </case>
  
</switch>
