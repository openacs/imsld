<master src="../../../lib/imsld-master">
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>
  <property name="imsld_include_mktree">1</property>

  <div class="float-left">
    <a href="@imsld_admin_url@" class="button" target="_top" 
      title="#imsld.Exit_Monitor#">#imsld.Exit_Monitor#</a>
  </div>
  <div class="frame-header">#imsld.Activities#</div>
  
  <br />

  @properties_tree;noquote@
  
  @user_activity;noquote@
  
  @html_tree;noquote@
  
  @aux_html_tree;noquote@
  
  <!-- Script needed to show environments in the proper frame -->
  <script type="text/javascript">
    var as = document.getElementsByTagName("a");
    for (var i = 0; i < as.length; i++) {
      var a = as[i];
      for( var x = 0; x < a.attributes.length; x++ ) {
        if( a.attributes[x].nodeName.toLowerCase() == 'href' ) {
          if ( a.attributes[x].nodeValue.match(/activity-frame/) ) {
            var enviromenturl = a.attributes[x].nodeValue.replace(/activity-frame/, "environment-frame");
            a.setAttribute('onClick',"parent.environment.location='" + enviromenturl + "'");
          }
        }
      } 
    }
  </script>

