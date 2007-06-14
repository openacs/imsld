<master src="../lib/imsld-master">
<property name="onload">init_activity()</property>
<property name="header_stuff">
<script type="text/javascript">

/* Optional: Temporarily hide the "tabber" class so it does not "flash"
   on the page as plain HTML. After tabber runs, the class is changed
   to "tabberlive" and it will appear. */

document.write('<style type="text/css">.tabber{display:none;}<\/style>');
</script>

<style type="text/css">
.show-hide { 
  position:absolute;
  top:0px;
  left:0px;
}
.hide { 
  display:none;
}
.notice {		
  font-size: x-small; 
  font-weight: bold; 
  background-color: #bbbbff; 
  padding:0px;
  margin:0px;
}
</style>
</property>

<span id="addc1" class="show-hide">
<a href="#" onClick="return _tp(false)" title="#imsld.Hide_1#" class="show-hide-icon_link"><img src="/resources/acs-subsite/stock_left.png" alt="#imsld.Hide#" title="#imsld.Hide#" border="0" align="top"/></a>
</span>
<span id="addc" style="display:none;" class="show-hide">
<a href="#" onClick="return _tp(true)" title="#imsld.Show_1#" class="show-hide-icon_link"><img src="/resources/acs-subsite/stock_right.png" alt="#imsld.Show#" title="#imsld.Show#" border="0" align="top"/></a>
</span>

<if @roles_template_p@ eq 1>
   <include src="support-activity-roles" supported_roles="@supported_roles@" run_id=@run_id@ activity_id=@activity_id@ supported_user_id=@supported_user_id@>
<div class="hide"> 
<a href="@activities;noquote@" title="#imsld.Activities#"></a>
</div>
</if>
<else>
@activities;noquote@
</else>

<p class="notice">#imsld.navigate#</p>
<iframe id="object" name="object"></iframe>



<script type="text/javascript">
<if @roles_template_p@ eq 1>
                dynamicSelect("supported-roles", "user-roles");
</if>

</script>

