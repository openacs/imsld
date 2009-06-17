    <!-- Include the arrow icon and JS for collapsing the left frames -->
    <span id="addc1" class="show">
      <a href="#" onClick="return _tp_div(false)" title="#imsld.Hide_1#" 
         class="show-hide-icon_link" style="float:left; padding-top:8px;">
        <img src="/resources/acs-subsite/stock_left.png" 
             alt="#imsld.Hide#" title="#imsld.Hide#" border="0" 
             align="top">
      </a>
    </span>
    <span id="addc" class="hide">
      <a href="#" onClick="return _tp_div(true)" title="#imsld.Show_1#" 
        class="show-hide-icon_link">
        <img src="/resources/acs-subsite/stock_right.png" 
           alt="#imsld.Show#" title="#imsld.Show#" border="0" 
           align="top">
      </a>
    </span>

  <if @roles_template_p@ eq 1>
    <include src="support-activity-roles" 
	supported_roles="@supported_roles@" 
	run_id=@run_id@ 
	activity_id=@activity_id@ 
	supported_user_id=@supported_user_id@>
    <div class="hide"> 
      <a href="@activities;noquote@" title="#imsld.Activities#"></a>
    </div>
  </if>
  <else>
    @activities;noquote@
    <!-- This message should appear only if there is more than one link! -->
    <p class="notice">#imsld.navigate#</p>
  </else>

  <iframe id="object" name="object" src="@iframe_activity_url@" style="left:0; top:0;" width="98%" height="60%"></iframe>

  <script type="text/javascript">
    <if @roles_template_p@ eq 1>
      dynamicSelect("supported-roles", "user-roles");
    </if>
  </script>

