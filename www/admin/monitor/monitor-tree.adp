<master src="../../../lib/imsld-master">
<property name="header_stuff">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <script src="/resources/acs-templating/mktree.js" language="javascript"></script>
    <link rel="stylesheet" href="/resources/acs-templating/mktree.css" media="all">
    <link rel="stylesheet" href="/resources/imsld/imsld.css" media="all">
    <link rel="stylesheet" href="/resources/theme-zen/css/main.css" media="all">
</property>

<a href="@imsld_admin_url@" class="button" target="_top" title=\"#imsld.Exit#\">#imsld.Exit#</a>
<br />
@properties_tree;noquote@
@html_tree;noquote@
@aux_html_tree;noquote@

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

</body>

