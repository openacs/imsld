<master src="../lib/imsld-master">

#imsld.Monitoring#: @monitoring_user_name@

<if @users_in_role:rowcount@ gt 0>
<form name="choose-user" action="monitor-frame">
<select name="monitoring_user_id" id="users-in-role"
        onChange="submitForm(this.form, 'imsld_content')">
    <option value="select">#imsld.Select#</option>
    <multiple name="users_in_role">
        <if @users_in_role.role_user_id@ eq @monitoring_user_id@>
        <option value="@users_in_role.role_user_id@" selected="selected">@users_in_role.user_name@</option>
        </if><else>
        <option value="@users_in_role.role_user_id@">@users_in_role.user_name@</option>
        </else>
    </multiple>
</select>
<input type="hidden" name="run_id" value="@run_id@">
<input type="hidden" name="role_id" value="@role_id@">
<input type="hidden" name="monitor_id" value="@monitor_id@">
<input type="submit" name="ok" value="OK">
</form>
</if>

<div class="hide">
<a id="monitor_service_url" href="@monitor_service_url;noquote@" title="<# Monitor service #>"></a>
</div>

<iframe id="object" name="object"></iframe>

