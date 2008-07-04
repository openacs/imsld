<master src="../lib/imsld-master-div">
  <property name="imsld_include_mktree">1</property>

  <div class="float-left">
    <a href="@community_url@" class="button" target="_top" 
       title="#imsld.Exit#">#imsld.Exit#</a>
  </div>

  <div class="role_menu">
    <if @possible_roles:rowcount@ not nil and
        @possible_roles:rowcount@ gt 1>
      <include src="../lib/choice-select" &item_select="possible_roles"
        select_name="current_role_id"
        select_id="roles_list"
        selected_item=@user_role_id@
        select_string=@select_string@
        run_id=@run_id@>
    </if>
  </div>

  <div class="frame-header">#imsld.Activities#</div>

  <br />

  @html_tree;noquote@

  @aux_html_tree;noquote@

  <if @user_message@ not nil>
    @user_message@
  </if>

  <!-- Script needed to show environments in the proper frame -->
  <script type="text/javascript">
    var as = document.getElementsByTagName("a");
    for (var i = 0; i < as.length; i++) {
      var a = as[i];
      for( var x = 0; x < a.attributes.length; x++ ) {
        if( a.attributes[x].nodeName.toLowerCase() == 'href' ) {
          if ( a.attributes[x].nodeValue.match(/activity-frame/) ) {
            var environmenturl = a.attributes[x].nodeValue.replace(/activity-frame/, "environment-frame");
            var oldEvent = a.onclick;
            a.onclick = function() {
              if (oldEvent) { oldEvent(); }
              loadEnvironment(environmenturl);
              return(false);
            }
            //a.setAttribute('onClick', newEvent);
          }
        }
      } 
    }
  </script>



