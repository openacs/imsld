<form action="#">
<div>
<select id="supported-roles">
    <option value="select">Select role to support...</option>
    <multiple name="role_info">
        <option value="@role_info.role_id@">@role_info.role_name@</option>
    </multiple>
</select>
<select id="user-roles">
    <option class="select" value="select">Select user to support...</option>
    <multiple name="supported_users_in_role">
    <option class="@supported_users_in_role.role_id@" value="@supported_users_in_role.member_id@">@supported_users_in_role.username@</option>
    </multiple>
</select>
</div>
</form>


