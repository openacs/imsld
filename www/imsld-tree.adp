  <div class="float-left">
    <a href="@community_url@" class="button" 
       title="#imsld.Finish#">#imsld.Finish#</a>
  </div>

  <div class="role_menu">
    <if @possible_roles:rowcount@ not nil and
        @possible_roles:rowcount@ gt 1>
      <include src="../lib/choice-select" &item_select="possible_roles"
        select_name="current_role_id"
        select_id="roles_list"
        selected_item=@user_role_id@
        select_string=@select_string@
        run_id=@run_id@
        conn_url="imsld-tree"
        section="imsld_activity_tree">
    </if>
  </div>

  <div class="frame-header">#imsld.Activities#</div>

  <br>

  <include src="../lib/activity-tree" run_id="@run_id@" user_id="@user_id@"
    next_activity_id_list="@next_activity_id@" />

  @aux_html_tree;noquote@

  <if @user_message@ not nil>
    @user_message@
  </if>

