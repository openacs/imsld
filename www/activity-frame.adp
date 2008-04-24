<master src="../lib/imsld-master">
  <property name="onload">init_activity()</property>
  <property name="header_stuff">
    <script type="text/javascript">
      /* Optional: Temporarily hide the "tabber" class so it does not "flash"
         on the page as plain HTML. After tabber runs, the class is changed
         to "tabberlive" and it will appear. */

      document.write('<style type="text/css">.tabber{display:none;}<\/style>');
    </script>
  </property>
  <property name="imsld_content_frame">1</property>

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

  <iframe id="object" name="object"></iframe>

  <script type="text/javascript">
    <if @roles_template_p@ eq 1>
      dynamicSelect("supported-roles", "user-roles");
    </if>
  </script>

