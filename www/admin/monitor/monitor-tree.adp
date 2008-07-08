<master src="../../../lib/imsld-master">
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>
  <property name="imsld_include_mktree">1</property>

  <div class="float-left">
    <a href="@imsld_admin_url@" class="button" target="_top" 
      title="#imsld.Exit_Cockpit#">#imsld.Exit_Cockpit#</a>
  </div>
  <div class="frame-header">#imsld.Activities#</div>
  
  <br />

  @properties_tree;noquote@
  
  @user_activity;noquote@
  
  @html_tree;noquote@
  
  @aux_html_tree;noquote@
  
