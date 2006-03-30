<master>


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
  </tr>
  <tr>
    <if @group_instance@ not eq 0>
      <include src="imsld-role-members">
    </if> 
</tr>
</table>

