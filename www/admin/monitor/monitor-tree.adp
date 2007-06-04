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

<style type="text/css">
li {
  padding: 5px 0px 0px 0px;
}
</style>
</head>
<body>
<a href="@imsld_admin_url@" class="button" target="_top" title=\"#imsld.Exit#\">#imsld.Exit#</a>
<br />
@properties_tree;noquote@
@html_tree;noquote@
@aux_html_tree;noquote@
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
