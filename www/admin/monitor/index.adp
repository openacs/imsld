<master src="../../../lib/imsld-master">
  <property name="title">@course_name@</property>
  <property name="imsld_include_mktree">1</property>
  <property name="imsld_content_frame">1</property>
  <property name="header_stuff">
    <link rel="stylesheet" href="/resources/theme-zen/css/main.css" media="all">
    <link rel="stylesheet" href="/resources/acs-templating/mktree.css" media="all">
    <style type="text/css">
      p.runtime {
        font-family:Verdana, Arial, Helvetica, sans-serif;
        text-align:center;  
        font-size: 11px;
        color: #ffffff;
        margin: 0px;
        padding: 0px 0px 0px 0px;
      }
      div.runtime {
        margin: 0px;
        padding: 0px 0px 0px 0px;
        top: 0px;
        background-color: #0000FF;
      }
    </style>

  </property>

    <div id="runinfo" class="frame">
        <include src="run-info" />
    </div>
    <div id="imsld_activity_tree" class="frame">
        <include src="monitor-tree" />
    </div>
    <div id="imsld_environment" class="frame">
      <if @activity_id@ not nil>
        <include src="environment-frame" />
      </if>
    </div>
    <div id="imsld_content" class="frame">
      <if @type@ not nil>
        <include src="properties-frame" />
      </if>
    </div>
