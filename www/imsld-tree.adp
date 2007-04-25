<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <meta http-equiv="refresh" content="20">
    <script src="/resources/acs-templating/mktree.js" language="javascript"></script>
    <link rel="stylesheet" href="/resources/acs-templating/mktree.css" media="all">

<SCRIPT>
    function confirmValue(myform){
        myform.submit()
    }
</SCRIPT>
<NOSCRIPT>
<br /><br />
#imsld.lt_Sorry_your_browser_do#
<br /><br />
</NOSCRIPT>

<style type="text/css">
ul {
font-family: Verdana, Arial, Helvetica, sans-serif;
font-size: 12px;
font-style: normal;
font-weight: normal;
font-variant: normal;
text-decoration: none;
text-transform: none;
text-indent: -15px;
padding: 0px;
margin: 0px;
}
div.role_menu {
    text-align: right;
    font-size: 80%;
	padding: 0px;      
	margin: 0px;
    top: 0px;
    right: 0px;
} 
a.button  {
	text-align: center;
	border: 3px outset #00b;
	background-color: #007; 
	color: #fff;
	font-weight: bold;
	font-size: 10px;
	text-decoration: none;
	padding: 0px;      
	margin: 0px;
    top: 0px;
    left: 0px;
}
a.button:hover  {
	color: #fff;
	background-color: #00d;
	border: 3px inset #00b;
}
</style>
</head>
<body>
<a href="@community_url@"  style="display: block; position: fixed;" class="button" target="_top">#imsld.Exit#</a>
<div class="role_menu">
<form name="choose-role">
<select name="current_role_id" id="roles_list" onChange="confirmValue(this.form)">
<multiple name="possible_roles">
    <if @possible_roles.role_id@ eq @user_role_id@>
        <option value=@possible_roles.role_id@ selected="selected">@possible_roles.role_name@</option>
    </if><else>
        <option value=@possible_roles.role_id@>@possible_roles.role_name@</option>
    </else>
</multiple>
</select>
<input type="hidden" name="run_id" value=@run_id@ />
<input type="submit" name="ok" value="OK" />
</form>
</div>
@html_tree;noquote@
@aux_html_tree;noquote@
<if @user_message@ not nil>
@user_message@
</if>
</body>

<script type="text/javascript">
var as = document.getElementsByTagName("a");
for (var i = 0; i < as.length; i++) {
  var a = as[i];
  for( var x = 0; x < a.attributes.length; x++ ) {
    if( a.attributes[x].nodeName.toLowerCase() == 'href' ) {
      if ( a.attributes[x].nodeValue.match(/activity-frame/) ) {
        var enviromenturl = a.attributes[x].nodeValue.replace(/activity-frame/, "environment-frame");
        a.setAttribute('onClick',"parent.environment.location='" + enviromenturl + "'");
      }
    }
  }
}
</script>

<SCRIPT>
  document.forms['choose-role'].elements['ok'].style.display="none"
</SCRIPT>

</html>


