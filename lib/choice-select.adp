<if @item_select:rowcount@ gt 0>
  <form name="choose" action="">

    <if @aux_pre_text@ not nil>@aux_pre_text;noquote@</if>

    <select name="@select_name@" id="@select_id@" 
            onChange="confirmValue(this.form)">
      <if @selected_item@ eq "">
        <option value="select">@select_string@</option>
      </if>
      <multiple name="item_select">
        <if @selected_item@ not nil and @item_select.item_id@ eq @selected_item@>
          <option value="@item_select.item_id@" 
                  selected="selected">@item_select.item_name@</option>
        </if><else>
          <option value="@item_select.item_id@">@item_select.item_name@</option>
        </else>
      </multiple>
    </select>
    <if @run_id@ not nil>
      <input type="hidden" name="run_id" value="@run_id@">
    </if>
    <if @role_id@ not nil>
      <input type="hidden" name="role_id" value="@role_id@">
    </if>
    <if @type@ not nil>
      <input type="hidden" name="type" value="@type@">
    </if>
    <if @monitor_id@ not nil>
      <input type="hidden" name="monitor_id" value="@monitor_id@">
    </if>
    <if @aux_post_text@ not nil>@aux_post_text;noquote@</if>
    <input type="submit" name="ok" value="OK">
  </form>
  <script type="text/javascript">
      document.forms['choose'].elements['ok'].style.display="none"
      function confirmValue(myform) {
        myform.submit()
      }
  </script>
</if>
