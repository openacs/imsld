<master src="../../../lib/imsld-master">
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>
<property name="header_stuff">
<script type="text/javascript">
function _tp(a){
   var ab=document.getElementById("addc");
   var ac=document.getElementById("addc1");

   if (a) {
     ai=''; 
     aj='none';
     parent.document.getElementsByTagName("frameset")[1].cols='30%,*';
   } else {
     ai='none';
     aj='';
     parent.document.getElementsByTagName("frameset")[1].cols='0%,*';
   }

   ac.style.display=ai;
   ab.style.display=aj;
   
   return false;
}
</script>
<style  type="text/css">
.show-hide { 
  position:relative;
  top:0px;
  left:0px;
}
</style>
</property>

<span id="addc1" class="show-hide">
<a href="#" onClick="return _tp(false)" title="#imsld.Hide_1#" class="show-hide-icon_link"><img src="/resources/acs-subsite/stock_left.png" alt="#imsld.Hide#" title="#imsld.Hide#" border="0" align="top"/></a>
</span>
<span id="addc" style="display:none;" class="show-hide">
<a href="#" onClick="return _tp(true)" title="#imsld.Show_1#" class="show-hide-icon_link"><img src="/resources/acs-subsite/stock_right.png" alt="#imsld.Show#" title="#imsld.Show#" border="0" align="top"/></a>
</span>

@list_header@
<br /><br />
<listtemplate name="related_users"></listtemplate>
<br />


