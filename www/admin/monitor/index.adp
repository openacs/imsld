<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN"
   "http://www.w3.org/TR/html4/frameset.dtd">
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>@course_name@</title>
  </head>

  <frameset rows="%20,*" title="#imsld.IMSLD_Monitor#">
    <frame src="run-info?run_id=@run_id@" name="run-info" title="#imsld.Run_Information#">
    <frameset id="right-column" cols="30%,*">
      <frameset rows="70%,*" title="#imsld.Menu_area#">
      <frame src="monitor-tree?run_id=@run_id@" name="toc" title="#imsld.Menu#">
      <frame src="" name="environment" title="#imsld.Environment#">
    </frameset>  
    <frame src="" name="content" title="#imsld.Contents#">
  </frameset>
</html>
