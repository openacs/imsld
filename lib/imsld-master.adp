@doc.type;noquote@
<html<if @doc.lang@ not nil> lang="@doc.lang;noquote@"</if>>
  <head>
    <title<if @doc.title_lang@ not nil and @doc.title_lang@ ne @doc.lang@> lang="@doc.title_lang;noquote@"</if>>@doc.title;noquote@</title>
    <multiple name="meta">
      <meta<if @meta.http_equiv@ not nil> http-equiv="@meta.http_equiv;noquote"</if>
           <if @meta.name@ not nil> name="@meta.name;noquote@"</if>
           <if @meta.scheme@ not nil> scheme="@meta.scheme;noquote@"</if>
           <if @meta.lang@ not nil and @meta.lang@ ne @doc.lang@> lang="@meta.lang;noquote@"</if> content="@meta.content@">>
    </multiple>
    <multiple name="link">
      <link rel="@link.rel;noquote@" href="@link.href;noquote@"<if @link.lang@ not nil and @link.lang@ ne @doc.lang@> lang="@link.lang;noquote@"</if>
      <if @link.title@ not nil> title="@link.title;noquote@"</if>
      <if @link.type@ not nil> type="@link.type;noquote@"</if>
      <if @link.media@ not nil> media="@link.media@"</if>/></multiple>
    <multiple name="script">
      <script type="@script.type;noquote@"<if @script.src@ not nil> src="@script.src;noquote@"</if>
      <if @script.charset@ not nil> charset="@script.charset;noquote@"</if>
      <if @script.defer@ not nil> defer="@script.defer;noquote@"</if>>
      <if @script.content@ not nil>@script.content;noquote@
      </if></script></multiple>
    <if @head@ not nil>@head;noquote@</if>
    <if @imsld_include_mktree@ not nil>
      <link rel="stylesheet" href="/resources/acs-templating/mktree.css" 
            type="text/css" media="all"/>
      <script type="text/javascript" 
              src="/resources/acs-templating/mktree.js"></script>
    </if>
  </head>
  <body<if @body.class@ not nil> class="@body.class;noquote@"</if><if @body.id@ not nil> id="@body.id;noquote@"</if><if @event_handlers@ not nil>@event_handlers;noquote@</if>>
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

    <if @acs_blank_master__htmlareas@ not nil>
      <textarea id="holdtext" style="display: none;" rows="1" cols="1"></textarea>
    </if>

    <if @imsld_content_frame@ not nil>
      <!-- Include the arrow icon and JS for collapsing the left frames -->
      <span id="addc1" class="show-hide" style="display:none">
        <a href="#" onClick="return _tp(false)" title="#imsld.Hide_1#" 
           class="show-hide-icon_link">
          <img src="/resources/acs-subsite/stock_left.png" 
               alt="#imsld.Hide#" title="#imsld.Hide#" border="0" 
               align="top"/>
        </a>
      </span>
      <span id="addc" style="display:none;" class="show-hide">
        <a href="#" onClick="return _tp(true)" title="#imsld.Show_1#" 
           class="show-hide-icon_link">
          <img src="/resources/acs-subsite/stock_right.png" 
               alt="#imsld.Show#" title="#imsld.Show#" border="0" 
               align="top"/>
        </a>
      </span>
      <script type="text/javascript">
	document.getElementById("addc1").style.display="";

        function _tp(a){
          var ab=document.getElementById("addc");
          var ac=document.getElementById("addc1");

          if (a) {
            ai=''; 
            aj='none';
            parent.document.getElementsByTagName("frameset")[1].cols='30%,*';
          } else {
            ai='none';
            aj='';
            parent.document.getElementsByTagName("frameset")[1].cols='0%,*';
          }
  
          ac.style.display=ai;
          ab.style.display=aj;
   
          return false;
        }
      </script>
    </if>

    <slave>

  </body>
</html>
