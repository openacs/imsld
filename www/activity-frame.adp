<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<style type="text/css">

/*Nav bar styles*/

ul.nav,
.nav ul{
margin: 0;
padding: 0;
cursor: default;
list-style-type: none;
display: inline;
}

ul.nav{
display: table;
}

ul.block{
width: 100%;
table-layout: fixed;
}

ul.nav>li{
display: table-cell;
position: relative;
padding: 2px 6px;
}
/*
ul.nav>li:hover{
padding-right: 1px;
}*/

ul.nav li>ul{
display: none;
position: absolute;
max-width: 40ex;
margin-left: -6px;
margin-top: 2px;
}

ul.nav li:hover>ul{
display : block;
}

.nav ul li a{
display: block;
padding: 2px 10px;
}

/*Menu styles*/

ul.nav,
.nav ul,
.nav ul li a{
background-color: #fff;
color: #369;
}

ul.nav li:hover,
.nav ul li a:hover{
background-color: #369;
color: #fff;
}

ul.nav li:active,
.nav ul li a:active{
background-color: #036;
color: #fff;
}

ul.nav,
.nav ul{
border: 1px solid #369;
}

.nav a{
text-decoration: none;
}

</style>

</head>
<body>

@activities;noquote@

<object data="index" type="text/html" id="object"></object>
<!-- <iframe id="object"> -->

<a href="#" onClick="objecturl('..')">hola</a>
</body>
<script type="text/javascript">
function resizeobject() {
f = document.forms[0];
o = document.getElementById('object');
o.height = window.innerHeight - o.style.top - 50;
o.width = window.innerWidth - o.style.left - 30;
}
window.onload = resizeobject;
window.onresize = resizeobject;

function objecturl(url1) {
o = document.getElementById('object');
o.data = url1;
}

</script>

</html>
