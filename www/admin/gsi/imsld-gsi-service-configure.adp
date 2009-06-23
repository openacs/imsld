<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>

<switch @state@>
    <case value="unchecked">
        <include src="imsld-gsi-show-service-requirements" gservice_id=@gservice_id@>
        <a href="@check_button@" title="check this service">Check this service</a>
        <a href="@back_button@" title="Back to service alternatives">Back to all alternatives</a>
    </case>

    <case value="checked">
        <include src="imsld-gsi-show-service-requirements" gservice_id=@gservice_id@>
        <include src="imsld-gsi-show-service-response" plugin_URI=@plugin_URI@ run_id=@run_id@ gservice_id=@gservice_id@>
        <a href="@refresh_button@" title="Update values">Update values</a>
        <a href="@choose_button@" title="Choose this service">Choose this service</a>
        <a href="@back_button@" title="Back to service alternatives">Back to all alternatives</a>
    </case>

    <case value="chosen">
        <include src="imsld-gsi-show-service-requirements" gservice_id=@gservice_id@>
        <include src="imsld-gsi-show-service-response" plugin_URI=@plugin_URI@ run_id=@run_id@ gservice_id=@gservice_id@>
        <include src="imsld-gsi-show-service-user-mapping" plugin_URI=@plugin_URI@ run_id=@run_id@ gservice_id=@gservice_id@>
        <a href="@map_button@" title="Finish user mapping">Finish user mapping</a>
    </case>

    <case value="mapped">
        <include src="imsld-gsi-show-service-requirements" gservice_id=@gservice_id@>
        <include src="imsld-gsi-show-service-response" plugin_URI=@plugin_URI@ run_id=@run_id@ gservice_id=@gservice_id@>
        <include src="imsld-gsi-show-service-user-mapping" plugin_URI=@plugin_URI@ run_id=@run_id@ gservice_id=@gservice_id@ mapped_p="t">
        <a href="@configure_button@" title="Finish service configuration">Finish service configuration</a>
    </case>

    <case value="configured">
        <include src="imsld-gsi-show-service-requirements" gservice_id=@gservice_id@>
        <include src="imsld-gsi-show-service-response" plugin_URI=@plugin_URI@ run_id=@run_id@ gservice_id=@gservice_id@>
        <include src="imsld-gsi-show-service-user-mapping" plugin_URI=@plugin_URI@ run_id=@run_id@ gservice_id=@gservice_id@ mapped_p="t">
        <include src="imsld-gsi-show-service-configurated" plugin_URI=@plugin_URI@ run_id=@run_id@ gservice_id=@gservice_id@ still_waiting_p=@still_waiting_p@>
    </case>


</switch>

