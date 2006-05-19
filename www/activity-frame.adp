<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<script type="text/javascript" src="/resources/imsld/tabber.js"></script>
<script type="text/javascript" src="/resources/imsld/dynamicselect.js"></script>
<link rel="stylesheet" href="/resources/imsld/example.css" TYPE="text/css" MEDIA="screen">
<link rel="stylesheet" href="/resources/imsld/example-print.css" TYPE="text/css" MEDIA="print">

<script type="text/javascript">

/* Optional: Temporarily hide the "tabber" class so it does not "flash"
   on the page as plain HTML. After tabber runs, the class is changed
   to "tabberlive" and it will appear. */

document.write('<style type="text/css">.tabber{display:none;}<\/style>');
</script>

<style type="text/css">

</style>

</head>
<body>

<if @flag@ not nil>
   <include src="support-activity-roles" supported_roles="@supported_roles@" run_id="@run_id@">
</if>

@activities;noquote@
<!-- <object data="index" type="text/html" id="object"></object> -->
<iframe id="object" name="object"></iframe>

<!-- <a href="#" onClick="objecturl('..'); return false">hola</a> -->
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

<if @flag@ not nil>
    <script type="text/javascript">
                dynamicSelect("supported-roles", "user-roles");
    </script>
</if>

</html>
