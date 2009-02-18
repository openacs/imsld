
<ul class="mktree">
  <li class="liOpen">
    @imsld_title@
    <ul>
      <multiple name="activities">
        <li id="activity_@activities.activity_id@">
          <include src="activity" run_id="@run_id@" type="@activities.type@"
            activity_id="@activities.activity_id@" imsld_id="@imsld_id@"
            play_id="@activities.play_id@" act_id="@activities.act_id@" />
        </li>
      </multiple>
    </ul>
  </li>
</ul>
