<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>
  <property name="header_stuff">
   <link rel="stylesheet" type="text/css" media="all" href="/resources/imsld/imsld.css">
<style type="text/css">
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

