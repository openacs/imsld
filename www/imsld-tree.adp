<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <script src="/resources/acs-templating/mktree.js" language="javascript"></script>
    <link rel="stylesheet" href="/resources/acs-templating/mktree.css" media="all">
    <link rel="stylesheet" href="/resources/imsld/imsld.css" media="all">

<SCRIPT>
    function confirmValue(myform){
        myform.submit()
    }
</SCRIPT>
</head>
<body>
<a href="@community_url@" class="button" target="_top" title="#imsld.Exit#">#imsld.Exit#</a>
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


