
<ul class="mktree">
  <li class="liOpen">
    @imsld_title@
    <ul>
      <multiple name="activities">
        <li class="liOpen"><include src="../play" play_id="@activities.play_id@" />
          <ul>
            <group column="play_id">
                <li><include src="../act" act_id="@activities.act_id@" />
                    <ul>
                      <group column="act_id">
                        <li id="activity_@activities.activity_id@">
                          <include src="activity" run_id="@run_id@" type="@activities.type@"
                            activity_id="@activities.activity_id@" imsld_id="@imsld_id@"
                            play_id="@activities.play_id@" act_id="@activities.act_id@" />
                        </li>
                      </group>
                    </ul>
                </li>
              </group>
            </ul>
        </li>
      </multiple>
    </ul>
  </li>
</ul>
