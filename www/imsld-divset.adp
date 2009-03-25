<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
            "http://www.w3.org/TR/html4/strict.dtd">
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>@course_name@</title>
    <style type="text/css">
      div#imsld_activity_tree {
        top:0;
        height:49%;
      }
      
      div#imsld_environment {
        top:49%;
        height:49%;
      }
      
      div#imsld_content {
        top:0;
        height:98%;
      }
      
    </style>
  </head>
  <body> 
    <div id="imsld_activity_tree" class="frame">
        <include src="imsld-tree" />
    </div>
    <div id="imsld_environment" class="frame">
      <if @activity_id@ not nil>
        <include src="environment-frame" />
      </if>
    </div>
    <div id="imsld_content" class="frame">
      <if @activity_id@ not nil>
        <include src="activity-frame" />
      </if>
    </div>
  </body>
</html>
