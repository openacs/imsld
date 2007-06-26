<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>
  <property name="header_stuff">
<style type="text/css">

.one-row {
  clear:both;
  padding-right:20px;
}
.one-element {
  float:left;
  display:inline;
  margin:0px;
  padding-right:30px;
}
.roles-confirm {
  float:left;
  text-indent:-180px;
  margin-top:40px;
}
ul {
  text-indent: 0px;
}
</style>
  </property>

<SCRIPT>
    function confirmValue(myform){
        myform.submit()
    }
</SCRIPT>

<div class="one-row">
  <div class="one-element">
   <formtemplate id="choose_role"></formtemplate>
  </div>
  <if @role@ not eq 0>
  <div class="one-element">
      <include src="imsld-groups">
  </div>
   </if> 
   <if @finishable@ not eq 0>
  <div class="roles-confirm">
     <formtemplate id="finish_management"></formtemplate>
  </div>
   </if>
</div>

<if @group_instance@ not eq 0>
  <include src="imsld-role-members">
</if> 


<SCRIPT>
  document.forms['choose_role'].elements['formbutton:ok'].style.display="none"
</SCRIPT>

