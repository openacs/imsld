<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
            "http://www.w3.org/TR/html4/strict.dtd">
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>@course_name@</title>
    <style type="text/css">
      div#tree {
        top:0;
        height:49%;
      }
      
      div#environment {
        top:49%;
        height:49%;
      }
      
      div#content {
        top:0;
        height:98%;
      }
      
    </style>
  </head>
  <body> 
    <div id="tree" class="frame">
        <include src="imsld-tree" />
    </div>
    <div id="environment" class="frame">
      <if @activity_id@ not nil>
        <include src="environment-frame" />
      </if>
    </div>
    <div id="content" class="frame">
      <if @activity_id@ not nil>
        <include src="activity-frame" />
      </if>
    </div>
  </body>
</html>
