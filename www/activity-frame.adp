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
<!--
html {margin:13px; border:15px; padding:3px;}
body {margin:3px; border:3px; padding:5px;}
-->
</style>
<SCRIPT>
    function confirmValue(myform){
        myform.submit()
    }
</SCRIPT>
</head>
<body>

<span id="addc1" style="position:absolute;top:0px;left:0px;">
<a href="#" onClick="return _tp(false)" title="Hide panel" class="show-hide-icon_link"><img src="/resources/acs-subsite/stock_left.png" alt="#imsld.Hide#" border="0" align="top"/></a>
</span>
<span id="addc" style="display:none;position:absolute;top:0px;left:0px;">
<a href="#" onClick="return _tp(true)" title="Show panel" class="show-hide-icon_link"><img src="/resources/acs-subsite/stock_right.png" alt="#imsld.Show#" border="0" align="top"/></a>
</span>

<if @roles_template_p@ eq 1>
   <include src="support-activity-roles" supported_roles="@supported_roles@" run_id=@run_id@ activity_id=@activity_id@ supported_user_id=@supported_user_id@>

<div style="display:none;">
<a href="@activities;noquote@"></a>
</div>
</if>
<else>
@activities;noquote@
</else>

<iframe id="object" name="object"></iframe>

</body>
<script type="text/javascript">
function resizeobject() {
f = document.forms[0];
o = document.getElementById('object');
var bodies = document.getElementsByTagName("body");
var body = bodies[0];
if (document.documentElement && document.documentElement.currentStyle && typeof document.documentElement.clientWidth != "undefined" && document.documentElement.clientWidth != 0)
{
o.width = document.documentElement.clientWidth + 2*parseInt(document.documentElement.currentStyle.borderWidth,10) - o.style.left;
o.height = document.documentElement.clientHeight + 2*parseInt(document.documentElement.currentStyle.borderWidth,10) - o.style.top;
}
else if (document.all && document.body && typeof document.body.clientWidth != "undefined")
{
o.width = document.body.clientWidth + 2*parseInt(document.body.currentStyle.borderWidth,10) - o.style.left;
o.height = document.body.clientHeight + 2*parseInt(document.body.currentStyle.borderWidth,10) - o.style.top;
}
else if (window.innerWidth)
{
o.width = window.innerWidth - o.style.left - 30;
o.height = window.innerHeight - o.style.top - 50;
}
else if (document.body && typeof document.body.clientWidth != "undefined")
{
o.width = document.body.clientWidth - o.style.left;
o.height = document.body.clientHeight - o.style.top;
};

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
for (var i = 0; i < as.length; i++) {
  if (!as[i].getAttribute('href').match(/#/i)) {
    document.getElementById('object').src = as[i].getAttribute('href');
    break;
  }
}
</script>

<script type="text/javascript">
function _tp(a){
   var ab=document.getElementById("addc");
   var ac=document.getElementById("addc1");

   if (a) {
     ai=''; 
     aj='none';
     parent.document.getElementsByTagName("frameset")[0].cols='30%,*';
   } else {
     ai='none';
     aj='';
     parent.document.getElementsByTagName("frameset")[0].cols='0%,*';
   }

   ac.style.display=ai;
   ab.style.display=aj;
   
   return false;
}


</script>

<if @roles_template_p@ not nil>
    <script type="text/javascript">
                dynamicSelect("supported-roles", "user-roles");
    </script>
</if>

</html>
