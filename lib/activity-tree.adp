<ul>
  <li>
    @imsld_title@
    <ul id="mktree_activities" class="mktree">
      <multiple name="activities">
        <li id="mktree_activities_@activities.act_id@"><include src="act" act_id="@activities.act_id@" />
          <ul>
            <group column="act_id">
              <include src="activity" run_id="@run_id@" type="@activities.type@"
                user_id="@user_id@" activity_id="@activities.activity_id@"
                next_activity_id_list="@next_activity_id_list@" imsld_id="@imsld_id@"
                play_id="@activities.play_id@" act_id="@activities.act_id@"
                role_part_id="@activities.role_part_id@" />
            </group>
          </ul>
        </li>
      </multiple>
    </ul>
  </li>
</ul>
