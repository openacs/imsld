<master>

<SCRIPT>
    function confirmValue(myform){
        myform.submit()
    }
</SCRIPT>
<table  width="100%">
  <tr>
    <td>
  <formtemplate id="choose_role"></formtemplate>
    </td>
    <td>
    <h3>#imsld.Parent#</h3>

    <if @parent_role_name@ not nil>
        <ul>
            <li><a href=@parent_role_link@>@parent_role_name@</a></li>
        </ul>
    </if>
    <else>
        <p>#imsld.The#</p>
    </else>

    <td>
     &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
    </td>
   <td>
     <h3>#imsld.Descendant#</h3>
     <ul>
       <multiple name="subroles_names">
         <li><a href=@subroles_names.rolelink@>@subroles_names.rolename@</a></li>
       </multiple>
      </ul>
      <if @subroles_names:rowcount@ eq 0>
      <p>#imsld.There#</p>
      </if>
    </td>
   </td>
  </tr>
</table>

<h3>#imsld.Groups#</h3>
<listtemplate name="group_table"></listtemplate>
<br><br>
<a href="index">#imsld.Back#</a>
<SCRIPT>
  document.forms['choose_role'].elements['formbutton:ok'].style.display="none"
</SCRIPT>

