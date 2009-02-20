<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
            "http://www.w3.org/TR/html4/strict.dtd">
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>@course_name@</title>
  </head>
  <body> 
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
  </body>
</html>
