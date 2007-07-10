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

  var as = document.getElementsByTagName("a");
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
