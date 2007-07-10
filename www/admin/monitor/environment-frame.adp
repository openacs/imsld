<master src="../../../lib/imsld-master">
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>
  <property name="imsld_include_mktree">1</property>

  <div class="frame-header">@frame_header@</div>

  <if @environments@ not nil>@environments;noquote@</if>

  <script type="text/javascript">
    var as = document.getElementsByTagName("a");
    for (var i = 0; i < as.length; i++) {
      var a = as[i];
      a.setAttribute('target', 'content');
    }
  </script>
