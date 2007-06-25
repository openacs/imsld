<master src="../lib/imsld-master">
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>
<property name="header_stuff">
<style type="text/css">
ul {
  text-indent: 0px;
  padding: 10px 10px 5px 10px;
  margin: 10px;
}
</style>
</property>

  <p><strong>#imsld.lt_Select_a_role_to_send#</strong></p>
  <ul>
        <multiple name="all_email_data">
            <li>
                <a href="@all_email_data.send_mail_url@" title="#imsld.Send#">@all_email_data.title@</a> 
                       
            <br>
        </multiple>
  </ul>

