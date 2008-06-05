function confirmValue(myform) {
  myform.submit();
}

/*==================================================*/

function resizeobject() {
  f = document.forms[0];
  o = document.getElementById('object');
  var bodies = document.getElementsByTagName("body");
  var body = bodies[0];
  if (document.documentElement && document.documentElement.currentStyle && typeof document.documentElement.clientWidth != "undefined" && document.documentElement.clientWidth != 0)
    {
      o.width = document.documentElement.clientWidth + 2*parseInt(document.documentElement.currentStyle.borderWidth,10) - o.style.left;
      o.height = document.documentElement.clientHeight + 2*parseInt(document.documentElement.currentStyle.borderWidth,10) - o.style.top;
    }
  else if (document.all && document.body && typeof document.body.clientWidth != "undefined")
    {
      o.width = document.body.clientWidth + 2*parseInt(document.body.currentStyle.borderWidth,10) - o.style.left;
      o.height = document.body.clientHeight + 2*parseInt(document.body.currentStyle.borderWidth,10) - o.style.top;
    }
  else if (window.innerWidth)
    {
      o.width = window.innerWidth - o.style.left - 30;
      o.height = window.innerHeight - o.style.top - 50;
    }
  else if (document.body && typeof document.body.clientWidth != "undefined")
    {
      o.width = document.body.clientWidth - o.style.left;
      o.height = document.body.clientHeight - o.style.top;
    };

  if (document.getElementById('content')) {
    o.width = '99%';
    o.height = '78%';
  }

}

/*==================================================*/

function objecturl(url) {
  var o = document.getElementById('object');
  o.src = url;
}

/*==================================================*/

right_frame_width_percentage = "30%,*"
function _tp(a){
   var ab=document.getElementById("addc");
   var ac=document.getElementById("addc1");

   if (a) {
     ai='show'; 
     aj='hide';
     parent.document.getElementById("right-column").cols= right_frame_width_percentage;
   } else {
     /* collapse the left panel */
     ai='hide';
     aj='show';
     right_frame_width_percentage = parent.document.getElementById("right-column").cols;
     parent.document.getElementById("right-column").cols= '0%, *';
   }

   ac.className=ai;
   ab.className=aj;
   
   return false;
}

/*==================================================*/

function init_activity() {
  resizeobject();
  window.onresize = resizeobject;

  var content = document.getElementById("content");
  if (content == null) content = document;
  var as = content.getElementsByTagName("a");
  for (var i = 0; i < as.length; i++) {
    var a = as[i];
    a.setAttribute('target', 'object');
  }
  for (var i = 0; i < as.length; i++) {
    if (!as[i].getAttribute('href').match(/#/i)) {
      document.getElementById('object').src = as[i].getAttribute('href');
      break;
    }
  }

  tabberAutomatic();
}


function loadContent(url) {
  var objXmlHttp=null
  try {
    objXmlHttp = new XMLHttpRequest();            
  } catch(e) {
    try {
      objXmlHttp = new ActiveXObject("Microsoft.XMLHTTP");
    } catch(e) {
      try {
        objXmlHttp = new ActiveXObject("Msxml2.XMLHTTP");
      } catch(e) {
        alert("error opening XMLHTTP")
      }
    }
  }
        
  objXmlHttp.onreadystatechange = function() {
    if (objXmlHttp.readyState==4 || objXmlHttp.readyState=="complete"){
      document.getElementById('content').innerHTML = objXmlHttp.responseText;
      init_activity();
      convertTrees();
    }
  }

  objXmlHttp.open("GET",url,true);
  objXmlHttp.send(null);
  return(false);
}


/*==================================================*/

function loadEnvironment(url) {
  var objXmlHttp=null
  try {
    objXmlHttp = new XMLHttpRequest();            
  } catch(e) {
    try {
      objXmlHttp = new ActiveXObject("Microsoft.XMLHTTP");
    } catch(e) {
      try {
        objXmlHttp = new ActiveXObject("Msxml2.XMLHTTP");
      } catch(e) {
        alert("error opening XMLHTTP")
      }
    }
  }
        
  objXmlHttp.onreadystatechange = function() {
    if (objXmlHttp.readyState==4 || objXmlHttp.readyState=="complete"){
      document.getElementById('environment').innerHTML = objXmlHttp.responseText;
      var as = document.getElementById("environment").getElementsByTagName("a");
      for (var i = 0; i < as.length; i++) {
        var a = as[i];
        a.setAttribute('target', 'content');
        var oldEvent = a.onclick;
        a.onclick = function() {
          if (oldEvent) { oldEvent(); }
          loadContent(a.href);
          return(false);
        }
      }
      convertTrees();
    }
  }

  objXmlHttp.open("GET",url,true);
  objXmlHttp.send(null);
  return(false);
}



/*==================================================*/

function _tp_div(a){
   var ab=document.getElementById("addc");
   var ac=document.getElementById("addc1");

   if (a) {
     ai='show'; 
     aj='hide';
     document.getElementById("tree").style.width= '30%';
     document.getElementById("environment").style.width= '30%';
     document.getElementById("content").style.width= '70%';
     document.getElementById("content").style.left= '30%';
   } else {
     /* collapse the left panels */
     ai='hide';
     aj='show';
     document.getElementById("tree").style.width= '0';
     document.getElementById("environment").style.width= '0';
     document.getElementById("content").style.width= '100%';
     document.getElementById("content").style.left= '0';
   }

   ac.className=ai;
   ab.className=aj;
   
   return false;
}
