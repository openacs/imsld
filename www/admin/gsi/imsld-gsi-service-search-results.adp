<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>

<if @connected_p@ eq "t">
    <h2 class="center">Theese are the available alternatives to configure the service</h2>
    <div class="centered-table"><listtemplate name="lookup_results"></listtemplate></div>
</if>
<else>
    <p>Could not connect to the services registry. It seems that it is not available at the moment.</p>
    <p>Contact the administrator. (<a href="@return_addr@">Go back</a>)</p>
</else>
