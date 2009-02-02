<master src="../../../lib/imsld-master" />

<style type="text/css">
</style>

<script type="text/javascript">
</script>

<div style="padding:10px;">

  <table style="border:1px solid black;" class="perm-table">
    <tr>
      <td></td>
      <multiple name="activities">
        <td style="text-align:center;" class="focus"
          onmouseover="changeColor(this, '#eeeeee');"
          onmouseout="changeColor(this, '');">
          Activity @activities.rownum@
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
        <multiple name="activities">
          <td style="text-align:center;" class="focus"
            id="cell_@activities.activity_item_id@_@roles.group_id@"
            onmouseover="changeColor(this, '#eeeeee');"
            onmouseout="changeColor(this, '');">
            <a href="#" onclick="return showPermissionDialog(this,
              @activities.activity_item_id@, @roles.group_id@)">+</a>
          </td>
        </multiple>
      </tr>
    </multiple>
  </table>

</div>
