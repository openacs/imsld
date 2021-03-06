<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
            "http://www.w3.org/TR/html4/strict.dtd">
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">      
    <title>@doc.title@</title>

    <multiple name="link">
      <link rel="@link.rel;noquote@" href="@link.href;noquote@"<if @link.lang@ not nil and @link.lang@ ne @doc.lang@> lang="@link.lang;noquote@"</if>
      <if @link.title@ not nil> title="@link.title;noquote@"</if>
      <if @link.type@ not nil> type="@link.type;noquote@"</if>
      <if @link.media@ not nil> media="@link.media@"</if>></multiple>
    <multiple name="script">
      <script type="@script.type;noquote@"<if @script.src@ not nil> src="@script.src;noquote@"</if>
      <if @script.charset@ not nil> charset="@script.charset;noquote@"</if>
      <if @script.defer@ not nil> defer="@script.defer;noquote@"</if>>
      <if @script.content@ not nil>@script.content;noquote@
      </if></script></multiple>
    <if @imsld_include_mktree@ not nil>
      <link rel="stylesheet" href="/resources/acs-templating/mktree.css" 
            type="text/css" media="all">
      <script type="text/javascript">
        var mktree_remember = true;
      </script>
      <script type="text/javascript" 
              src="/resources/acs-templating/mktree.js"></script>
    </if>
    <if @head@ not nil>@head;noquote@</if>
    <multiple name="body_script">
      <script type="@body_script.type;noquote@"
        <if @body_script.src@ not nil> src="@body_script.src;noquote@"</if>
        <if @body_script.charset@ not nil> charset="@body_script.charset;noquote@"</if>
        <if @body_script.defer@ not nil> defer="@body_script.defer;noquote@"</if>>
        <if @body_script.content@ not nil>@body_script.content;noquote@</if>
      </script>
    </multiple>
    <if @user_messages:rowcount@ gt 0> 
      <div id="alert-message"> 
         <ul> 
           <multiple name="user_messages"> 
             <div class="alert"><strong>@user_messages.message;noquote@</strong></div> 
           </multiple> 
         </ul> 
      </div> 
    </if>     
    <if @acs_blank_master.rte@ not nil and @acs_blank_master__htmlareas@ not nil>
      <script language="JavaScript" type="text/javascript">
        <!--
          initRTE("/resources/acs-templating/rte/images/", 
            "/resources/acs-templating/rte/", 
            "/resources/acs-templating/rte/rte.css");
        // -->
      </script>
    </if>

    <if @acs_blank_master.xinha@ not nil and @acs_blank_master__htmlareas@ not nil>
      <script type="text/javascript">
        <!--
          xinha_editors = null;
          xinha_init = null;
          xinha_config = null;
          xinha_plugins = null;
          xinha_init = xinha_init ? xinha_init : function() {
            xinha_plugins = xinha_plugins ? xinha_plugins : [@xinha_plugins;noquote@];
            // THIS BIT OF JAVASCRIPT LOADS THE PLUGINS, NO TOUCHING  :)
            if(!HTMLArea.loadPlugins(xinha_plugins, xinha_init)) return;
            xinha_editors = xinha_editors ? xinha_editors :
            [
              <list name="acs_blank_master__htmlareas">
              '@acs_blank_master__htmlareas@'<if @acs_blank_master__htmlareas:rownum@ ne @acs_blank_master__htmlareas:rowcount@>,</if>
              </list>
            ];
            xinha_config = xinha_config ? xinha_config() : new HTMLArea.Config();
            @xinha_params;noquote@
            @xinha_options;noquote@
            xinha_editors = 
              HTMLArea.makeEditors(xinha_editors, xinha_config, xinha_plugins);
            HTMLArea.startEditors(xinha_editors);
          }
          window.onload = xinha_init;
        // -->
      </script>
    </if>

  </head>
  <body style="height:100%;"> 

    <if @acs_blank_master__htmlareas@ not nil>
      <textarea id="holdtext" style="display: none;" rows="1" cols="1"></textarea>
    </if>

    <slave>

  </body>
</html>
