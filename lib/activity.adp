<switch @type@>
  <case value="learning">
    <li class="@class@">
      <a href="@href@"
        onclick="return(loadContent('@div@'))">
        @activity_title@
      </a>
      <if @completed_activity_p@>
        <if @complete_act_id@ ne "">
          <img src="/resources/imsld/completed.png" alt="#imsld.completed#"
            title="#imsld.completed#" />
        </if>
      </if>
      <else>
        <if @is_visible_p@ and @user_choice_p@>
          <a href="@finish_href@" onclick="return(loadTree(this.href))"
            class="finish" title="#imsld.finish_activity#">#imsld.finish#</a>
        </if>
      </else>
      <include src="activity-resources-list" activity_item_id="@activity_item_id@"
        run_id="@run_id@" user_id="@user_id@" />
    </li>
  </case>

  <case value="support">
    <li class="@class@">
      <a href="@href@"
        onclick="return(loadContent('@div@'))">
        @activity_title@
      </a>
      <if @completed_activity_p@>
        <if @complete_act_id@ ne "">
          <img src="/resources/imsld/completed.png" alt="#imsld.completed#"
            title="#imsld.completed#" />
        </if>
      </if>
      <else>
        <if @is_visible_p@ and @user_choice_p@>
          <a href="@finish_href@" onclick="return(loadTree(this.href))"
            class="finish" title="#imsld.finish_activity#">#imsld.finish#</a>
        </if>
      </else>
      <include src="activity-resources-list" activity_item_id="@activity_item_id@"
        run_id="@run_id@" user_id="@user_id@" />
    </li>
  </case>

  <case value="structure">
    <if @started_p@>
      <li class="@class@">
        <a href="@href@"
          onclick="return(loadContent('@div@'))">
          @activity_title@
        </a>
        <if @referenced_activities:rowcount@>
          <ul>
            <multiple name="referenced_activities">
              <include src="activity" run_id="@run_id@"
                type="@referenced_activities.activity_type@" user_id="@user_id@"
                activity_id="@referenced_activities.activity_id@"
                next_activity_id_list="@next_activity_id_list@"
                imsld_id="@imsld_id@" play_id="@play_id@" act_id="@act_id@"
                role_part_id="@role_part_id@"
                structure_item_id="@structure_item_id@" />
            </multiple>
          </ul>
        </if>
      </li>
    </if>
  </case>
  
</switch>
