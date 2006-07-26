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
<SCRIPT>
    function confirmValue(myform){
        myform.submit()
    }
</SCRIPT>
</head>
<body>

<span id="addc1" style="align:left;display:;position:absolute;top:0px;left:0px;">
<a href="#" onClick="return _tp(false)" title="Hide panel" class="show-hide-icon_link"><img src="/resources/acs-subsite/stock_left.png" alt="Hide" border="0" align="top"/></a>
</span>
<span id="addc" style="align:left;display:none;position:absolute;top:0px;left:0px;">
<a href="#" onClick="return _tp(true)" title="Show panel" class="show-hide-icon_link"><img src="/resources/acs-subsite/stock_right.png" alt="Show" border="0" align="top"/></a>
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
