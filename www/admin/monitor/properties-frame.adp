
  <div class="frame-header">
    <if @item_select:rowcount@ not nil>
      <include src="../../../lib/choice-select" &="item_select"
        select_name=@select_name@
        select_id=@select_id@
        selected_item=@selected_item@
        select_string=@select_string@
        aux_pre_text=@frame_header@
        aux_post_text=@post_text;noquote@
        run_id=@run_id@
        role_id=@role_id@
        type=@type@
        section="imsld_content">
    </if><else>@frame_header;noquote@</else>
  </div>

  <br>

  <if @table_node@ not nil>
    <div class="centered-table">
      @table_node;noquote@
    </div>
  </if>

