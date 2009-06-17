
  <div class="float-left">
    <a href="@imsld_admin_url@" class="button" 
      title="#imsld.Exit_Cockpit#">#imsld.Exit_Cockpit#</a>
  </div>
  <div class="frame-header">#imsld.Activities#</div>
  
  <br>

  @properties_tree;noquote@
  
  @user_activity;noquote@
  
  <include src="../../../lib/monitor/activity-tree" run_id="@run_id@" />
  
  @aux_html_tree;noquote@
  
