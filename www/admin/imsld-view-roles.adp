<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>

<script type="text/javascript">
    function confirmValue(myform){
        myform.submit()
    }
</script>
<table  width="100%">
  <tr>
    <td>
  <formtemplate id="choose_role"></formtemplate>
    </td>
    <td>
    <h3>#imsld.Parent#</h3>

    <if @parent_role_name@ not nil>
        <ul>
            <li><a href=@parent_role_link@ title="#imsld.Parent_1#">@parent_role_name@</a></li>
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
     <if @subroles_names:rowcount@ gt 0>
       <ul>
         <multiple name="subroles_names">
           <li><a href=@subroles_names.rolelink@ title="#imsld.Subrole#">@subroles_names.rolename@</a></li>
         </multiple>
        </ul>
      </if>
      <else>
      <p>#imsld.There#</p>
      </else>
    </td>
  </tr>
</table>

<h3>#imsld.Groups#</h3>
<listtemplate name="group_table"></listtemplate>
<br><br>
<a href="index" title="#imsld.Back#">#imsld.Back#</a>
<script type="text/javascript">
  document.forms['choose_role'].elements['formbutton:ok'].style.display="none"
</script>

