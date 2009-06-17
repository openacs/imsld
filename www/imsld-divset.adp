<master src="../lib/imsld-master">
  <property name="title">@course_name@</property>
  <property name="imsld_include_mktree">1</property>
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


    <div id="imsld_activity_tree" class="frame">
        <include src="imsld-tree" />
    </div>
    <div id="imsld_environment" class="frame">
      <if @activity_id@ not nil>
        <include src="environment-frame" />
      </if>
    </div>
    <div id="imsld_content" class="frame">
      <if @activity_id@ not nil>
        <include src="activity-frame" />
      </if>
    </div>
