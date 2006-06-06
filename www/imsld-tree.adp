<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <meta http-equiv="refresh" content="20">
    <script src="/resources/acs-templating/mktree.js" language="javascript"></script>
    <link rel="stylesheet" href="/resources/acs-templating/mktree.css" media="all">
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
</style>
</head>
<body>
@html_tree;noquote@
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
</html>
