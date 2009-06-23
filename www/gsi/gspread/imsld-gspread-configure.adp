<html>
    <head>
        <title>Spreadsheet service configuration</title>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        <meta name="lang" content="es"/>
        <meta name="author" content="Luis de la Fuente Valentín"/>
    </head>
    <body>
        <h1>Spreadsheet form configuration</h1>

        <p>Welcome to the google spreadsheet service for Learning Design. This service offers a HTML page containing
        a form, where course participants can answer proposed questions. Later, you will be able to view all results in
        the spreadsheet where anwsers are automatically stored.</p>

        <p>Before using the service, you have to take some steps to finish its configuration.</p> 
        <!-- Set form file or url -->
        <h2>Set the form file or url</h2>
        <if @form_already_set_p@ not nil>
            <p><b>Note</b>:There is a form already set, here you have its configuration data.</p>
            <ul>
                <li>Type of form: @form_type@</li>
                <li><a href="@access_to_form@">Form content</a></li>
            </ul>
        </if>

        <p>If the form is not set, or you want to re-configure your service Select one of the options:</p>

        <p>Select a local file with the form</p>
        <formtemplate id="set-formfile"></formtemplate>

        <p>Or insert the URL where the form can be found</p>
        <formtemplate id="set-formURL"></formtemplate>

        <!-- Set the formkey -->
        <h2>Set the form's target</h2>
        <p>The version of the service you are using cannot automatically retrieve the form's target,
        so you have to set it up manually. Just follow these steps:</p>
        <ol>
            <li>Access the target spreadsheet ("View Responses" link in the course).</li>
            <li>Create a new form (Form -> Create a form). In case the form is already created, go to live form and jump to step 4.</li>
            <li>Just <b>save</b> the form and access the live form (you have a link in the bottom of the page). You don't need to edit the form.</li>
            <li>Copy the web page address you are in, and paste it below.</li>
        </ol>

        <formtemplate id="set-formkey"></formtemplate>
        <if @already_configured_p@ not nil>
            <p><b>Note</b>:The form is currently pointing to: @actual_formurl@</p>
        </if>
    </body>
</html>
