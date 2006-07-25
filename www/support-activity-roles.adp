#imsld.Supporting#

<form name="choose-supported-role" action="">
<div>
<select name="role_id" id="supported-roles" onChange="confirmValue(this.form)">
    <option value="select">Select role to support...</option>
    <multiple name="role_info">
        <option value="@role_info.role_id@">@role_info.role_name@</option>
    </multiple>
</select>
<select name="supported_user_id" id="user-roles" onChange="confirmValue(this.form)">
    <option class="select" value="select">Select user to support...</option>
    <multiple name="supported_users_in_role">
    <option class="@supported_users_in_role.role_id@" value="@supported_users_in_role.member_id@">@supported_users_in_role.username@</option>
    </multiple>
</select>
</div>
<input type="hidden" name="run_id" value="@run_id@">
<input type="hidden" name="activity_id" value="@activity_id@">
</form>


