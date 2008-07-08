<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
            "http://www.w3.org/TR/html4/strict.dtd">
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>@course_name@</title>
    <style type="text/css">
      div#tree {
        top:6%;
        height:47%;
      }
      
      div#environment {
        top:53%;
        height:46%;
      }
      
      div#content {
        top:6%;
        height:93%;
      }
      
    </style>

  </head>
  <body> 
    <div id="runinfo" class="frame">
        <include src="run-info" />
    </div>
    <div id="tree" class="frame">
        <include src="monitor-tree" />
    </div>
    <div id="environment" class="frame">
      <if @activity_id@ not nil>
        <include src="environment-frame" />
      </if>
    </div>
    <div id="content" class="frame">
      <if @type@ not nil>
        <include src="properties-frame" />
      </if>
    </div>
  </body>
</html>
