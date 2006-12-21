<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <script src="/resources/acs-templating/mktree.js" language="javascript"></script>
    <link rel="stylesheet" href="/resources/acs-templating/mktree.css" media="all">

<SCRIPT>
    function confirmValue(myform){
        myform.submit()
    }
</SCRIPT>

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
padding: 15px 0px 0px 0px;
margin: 0px;
}
div {
    text-align: right;
    font-size: 80%;
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
<a href="@imsld_admin_url@"  style="display: block; position: fixed;" class="button" target="_top">#imsld.Exit#</a>
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
