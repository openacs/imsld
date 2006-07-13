<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<SCRIPT>
    function confirmValue(myform){
        myform.submit()
    }
</SCRIPT>

</head>
<body>

#imsld.Monitoring#: @monitoring_user_name@

<if @users_in_role:rowcount@ gt 0>
<form name="choose-user" action="">
<select name="monitoring_user_id" id="users-in-role" onChange="confirmValue(this.form)">
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
</form>
</if>

<div style="display:none;">
<a href="@monitor_service_url;noquote@"></a>
</div>

<iframe id="object" name="object"></iframe>

</body>

<script type="text/javascript">
function resizeobject() {
f = document.forms[0];
o = document.getElementById('object');
o.height = window.innerHeight - o.style.top - 50;
o.width = window.innerWidth - o.style.left - 30;
}
resizeobject();
window.onresize = resizeobject;

function objecturl(url) {
var o = document.getElementById('object');
o.src = url;
}

</script>

<script type="text/javascript">
var as = document.getElementsByTagName("a");
for (var i = 0; i < as.length; i++) {
  var a = as[i];
  a.setAttribute('target', 'object');
}
document.getElementById('object').src = as[0].getAttribute('href');
</script>

<SCRIPT>
  document.forms['choose-user'].elements['formbutton:ok'].style.display="none"
</SCRIPT>

</html>
