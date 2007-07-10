<master src="../../../lib/imsld-master">
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>
  <property name="imsld_content_frame">1</property>

  <div class="frame-header">
    <if @item_select:rowcount@ not nil>
      <include src="../../../lib/choice-select" &="item_select"
        select_name=@select_name@
        select_id=@select_id@
        selected_item=@selected_item@
        select_string=@select_string@
        aux_pre_text=@frame_header@
        aux_post_text=@post_text;noquote@
        run_id=@run_id@>
    </if><else>@frame_header;noquote@</else>
  </div>

  <br />

  <if @member_id@ not nil>
    <div class="centered-table">
      <listtemplate name="activities"></listtemplate>
    </div>
  </if>
