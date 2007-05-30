<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>
  <property name="header_stuff">
<style  type="text/css">
.table {
  clear:both;
  padding-right:20px;
}
.row {
  float:left;
  display:inline;
  margin_0px;
  padding-right:30px;
}
.confirm {
  float:left;
  text-indent:-180px;
  margin-top:40px;
}
</style>
</property>


<SCRIPT>
    function confirmValue(myform){
        myform.submit()
    }
</SCRIPT>

<div class="table">
  <div class="row">
   <formtemplate id="choose_role"></formtemplate>
  </div>
  <if @role@ not eq 0>
  <div class="row">
      <include src="imsld-groups">
  </div>
   </if> 
   <if @finishable@ not eq 0>
  <div class="confirm">
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

