    <!-- Include the arrow icon and JS for collapsing the left frames -->
    <span id="addc1" class="show">
      <a href="#" onClick="return _tp_div(false)" title="#imsld.Hide# #imsld.Hide_1#" 
         class="show-hide-icon_link">
        <img src="/resources/imsld/application_side_contract.png" 
             alt="#imsld.Hide# #imsld.Hide_1#" border="0" 
             align="top">
      </a>
    </span>
    <span id="addc" class="hide">
      <a href="#" onClick="return _tp_div(true)" title="#imsld.Show# #imsld.Show_1#" 
        class="show-hide-icon_link">
        <img src="/resources/imsld/application_side_expand.png" 
           alt="#imsld.Show# #imsld.Show_1#" border="0" 
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
    <if @node_list:rowcount@ gt 1>
      <p class="notice">#imsld.navigate#</p>
    </if>
  </else>

  <iframe id="object" name="object" src="@iframe_activity_url@" style="left:0; top:0;" width="98%" height="60%"></iframe>

  <script type="text/javascript">
    <if @roles_template_p@ eq 1>
      dynamicSelect("supported-roles", "user-roles");
    </if>
  </script>

