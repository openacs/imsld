<master>


<SCRIPT>
    function confirmValue(myform){
        myform.submit()
    }
</SCRIPT>


<table border="0">
<tr>
  <td>
  <formtemplate id="choose_role"></formtemplate>
  </td>
  <td>
  <if @role@ not eq 0>
      <include src="imsld-groups">
  </if> 
  </td>

  <td>
    <if @finishable@ not eq 0>
     <formtemplate id="finish_management"></formtemplate>
    </if>
  </td>

  </tr>

    <if @group_instance@ not eq 0>
      <include src="imsld-role-members">
    </if> 

</table>

<SCRIPT>
  document.forms['choose_role'].elements['formbutton:ok'].style.display="none"
</SCRIPT>

