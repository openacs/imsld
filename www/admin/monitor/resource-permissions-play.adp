<master src="../../../lib/imsld-master" />

<style type="text/css">
  .perm-table {
    border-collapse: collapse;
  }
  .perm-table td.focus:hover {
  background-color: #cecece;
  }
  .perm-table td {
  width: 80px;
  }
</style>

<script type="text/javascript">
</script>

<div style="padding:10px;">

  <table style="border:1px solid black;" class="perm-table">
    <tr>
      <td></td>
      <multiple name="acts">
        <td style="text-align:center;" class="focus"
          onmouseover="changeColor(this, '#eeeeee');"
          onmouseout="changeColor(this, '');">
          <a href="resource-permissions-act?run_id=@run_id@&act_id=@acts.act_item_id@"
          onclick="return loadContent(this.href)" title="@acts.act_title@">Act @acts.rownum@</a>
        </td>
      </multiple>
    </tr>
    <multiple name="roles">
      <tr>
        <td class="focus"
          onmouseover="changeColor(this, '#eeeeee');"
          onmouseout="changeColor(this, '');">
          @roles.name@
        </td>
        <multiple name="acts">
          <td style="text-align:center;" class="focus"
            id="cell_@acts.act_item_id@_@roles.group_id@"
            onmouseover="changeColor(this, '#eeeeee');"
            onmouseout="changeColor(this, '');">
            <a href="#" onclick="return showPermissionDialog(this,
            @acts.act_item_id@, @roles.group_id@)">+</a>
          </td>
        </multiple>
      </tr>
    </multiple>
  </table>

</div>
