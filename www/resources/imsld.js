
function confirmValue(myform) {
  myform.submit();
}

/*==================================================*/

function resizeobject() {
  f = document.forms[0];
  o = document.getElementById('object');
  if (!o) {
    return;
  }
  var bodies = document.getElementsByTagName("body");
  var body = bodies[0];
  if (document.documentElement && document.documentElement.currentStyle && typeof document.documentElement.clientWidth != "undefined" && document.documentElement.clientWidth != 0)
    {
      o.width = document.documentElement.clientWidth - 6;
      o.height = document.documentElement.clientHeight - 6;
    }
  else if (document.all && document.body && typeof document.body.clientWidth != "undefined")
    {
      o.width = document.body.clientWidth - 6;
      o.height = document.body.clientHeight - 6;
    }
  else if (window.innerWidth)
    {
      o.width = window.innerWidth - 30;
      o.height = window.innerHeight - 50;
    }
  else if (document.body && typeof document.body.clientWidth != "undefined")
    {
      o.width = document.body.clientWidth - o.style.left;
      o.height = document.body.clientHeight - o.style.top;
    };

  if (document.getElementById('imsld_content')) {
    o.width = '99%';
    o.height = '78%';
  }

}

/*==================================================*/

function objecturl(url) {
  var o = document.getElementById('object');
  if (o) {
    o.src = url;
  }
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

  var content = document.getElementById("imsld_content");
  if (content == null) content = document;
  var as = content.getElementsByTagName("a");
  for (var i = 0; i < as.length; i++) {
    var a = as[i];
    a.setAttribute('target', 'object');
  }
  if (document.getElementById('object')) {
    for (var i = 0; i < as.length; i++) {
      if (!as[i].getAttribute('href').match(/#/i)) {
        document.getElementById('object').src = as[i].getAttribute('href');
        break;
      }
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
      document.getElementById('imsld_content').innerHTML = objXmlHttp.responseText;
      var e;
      if (document.forms['choose'] && (e = document.forms['choose'].elements['ok'])) {
        e.style.display = "none";
      }
      init_activity();
      convertTrees();
      if (unescape(url).match(/activity_id=|activity_item_id=/i)) {
        var env_url = url.replace(/[^\?]+/, "environment-frame");
        loadEnvironment(env_url);
      } else if ( unescape(url).match(/monitor-frame/i) ) {
	resizeobject();
	window.onresize = resizeobject;
	var a = document.getElementById("monitor_service_url");
	if ( a ) {
	  a.setAttribute('target', 'object');
	  if (a.getAttribute('href') != '') {
	    document.getElementById('object').src = a.getAttribute('href');
	  }
	}
	if (document.forms['choose-user']) {
	  document.forms['choose-user'].elements['ok'].style.display="none";
	}
      } else if ( !(unescape(url).match(/service_id=|learning_object_id=|imsld-finish-resource/i))) {
	document.getElementById('imsld_environment').innerHTML = '';
      }
      // tabberAutomatic();
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
      document.getElementById('imsld_environment').innerHTML = objXmlHttp.responseText;
//      var as = document.getElementById("imsld_environment").getElementsByTagName("a");
//      for (var i = 0; i < as.length; i++) {
//        var a = as[i];
//        var oldEvent = a.onclick;
//         a.onclick = function() {
//           if (oldEvent) { oldEvent(); }
//           loadContent(a.href);
//           return(false);
//         }
//      }
      convertTrees();
    }
  }

  objXmlHttp.open("GET",url,true);
  objXmlHttp.send(null);
  return(false);
}



/*==================================================*/

function loadTree(url) {
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
    if ((objXmlHttp.readyState==4 || objXmlHttp.readyState=="complete") && objXmlHttp.status==200){
      document.getElementById('imsld_activity_tree').innerHTML = objXmlHttp.responseText;
      delete window.treeClass;
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
     document.getElementById("imsld_activity_tree").style.width= '30%';
     document.getElementById("imsld_environment").style.width= '30%';
     document.getElementById("imsld_content").style.width= '70%';
     document.getElementById("imsld_content").style.left= '30%';
   } else {
     /* collapse the left panels */
     ai='hide';
     aj='show';
     document.getElementById("imsld_activity_tree").style.width= '0';
     document.getElementById("imsld_environment").style.width= '0';
     document.getElementById("imsld_content").style.width= '100%';
     document.getElementById("imsld_content").style.left= '0';
   }

   ac.className=ai;
   ab.className=aj;

   return false;
}

function submitForm(form, contentDiv) {
  var objXmlHttp=null;
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
      if (contentDiv !== undefined) {
        document.getElementById(contentDiv).innerHTML = objXmlHttp.responseText;
        var e;
        if (document.forms['choose'] && (e = document.forms['choose'].elements['ok'])) {
          e.style.display = "none";
        }
	if (contentDiv == "imsld_activity_tree" || contentDiv == "imsld_environment") {
	  try {
	    delete window.treeClass;
	  } catch(e) {
	    window.treeClass = undefined;
	  }
	  convertTrees();
	}
        if ( unescape(url).match(/monitor-frame/i) ) {
	  resizeobject();
	  window.onresize = resizeobject;
	  var a = document.getElementById("monitor_service_url");
	  if ( a ) {
	    a.setAttribute('target', 'object');
	    if (a.getAttribute('href') != '') {
	      document.getElementById('object').src = a.getAttribute('href');
	    }
	  }
	  if (document.forms['choose-user']) {
	    document.forms['choose-user'].elements['ok'].style.display="none";
	  }
      }
      }
    }
  }

  var method = (form.method == "") ? "POST" : form.method;

  var url = form.action;
  if (url == "") {
    l = window.location;
    url = l.protocol+'//'+l.host+l.pathname;
    if (url.match(/\/$/)) {
      url = url.replace(/\/$/, '');
    }
  }

  var list = new Array();
  for (var i=0; i<form.elements.length; i++) {
    var el = form.elements[i];
    if (el.type == "checkbox" || el.type == "radio" ) {
      if (el.checked) {
        list.push(encodeURIComponent(el.name)+"="+encodeURIComponent(el.value));
      }
    } else {
      list.push(encodeURIComponent(el.name)+"="+encodeURIComponent(el.value));
    }
  }

  var params = list.join("&");

  if (method.toUpperCase() == "POST") {
    var enctype = "application/x-www-form-urlencoded";
    objXmlHttp.open(method,url,true);
    objXmlHttp.setRequestHeader('Content-Type', enctype);
    objXmlHttp.setRequestHeader("Content-length", params.length);
    objXmlHttp.setRequestHeader("Connection", "close");
    objXmlHttp.send(params);
  } else {
    objXmlHttp.open(method,url+"?"+params,true);    
    objXmlHttp.send(null);
  }
  return(false);
}


function enableFields(check) {
  if (check.checked) {
    var parent = check.parentNode;
    var grandp = parent.parentNode;
    var tags = new Array('INPUT', 'SELECT');

    for (var i=0; i < tags.length; i++) {
      var items = grandp.getElementsByTagName(tags[i]);
      for (var j=0; j < items.length; j++) {
        if (!parent.isSameNode(items[j].parentNode.parentNode.parentNode) && items[j].type.toLowerCase() != 'radio') {
          items[j].disabled = true;
        } else {
          items[j].disabled = false;
        }
      }
    }
  }
}

function addEnvironment(div, env, run, act) {
  var formCode = '<form action="environment-edit" onsubmit="return submitForm(this, \'imsld_environment\')">';
  formCode += '<input type="hidden" name="environment_id" value="' + env + '" />';
  formCode += '<input type="hidden" name="run_id" value="' + run + '" />';
  formCode += '<input type="hidden" name="activity_id" value="' + act + '" />';
  formCode += '<div>Title:</div><input type="text" name="title" /><br />';
  formCode += '<div>URL:</div><input type="text" name="url" /><br />';
  formCode += '<input type="submit" name="submit" value="Add">';
  formCode += '</form>';
  div.innerHTML = formCode;

}

function editEnvironment(div, run, act, env, item, title, url) {
  var formCode = '<form action="environment-edit" onsubmit="return submitForm(this, \'imsld_environment\')">';
  formCode += '<input type="hidden" name="environment_id" value="' + env + '" />';
  formCode += '<input type="hidden" name="run_id" value="' + run + '" />';
  formCode += '<input type="hidden" name="activity_id" value="' + act + '" />';
  formCode += '<input type="hidden" name="item_id" value="' + item + '" />';
  formCode += '<div>Title:</div><input type="text" name="title" value="' + title + '" /><br />';
  formCode += '<div>URL:</div><input type="text" name="url" value="' + url + '" /><br />';
  formCode += '<input type="submit" name="submit" value="Save">';
  formCode += '</form>';
  div.innerHTML = formCode;

}

function changeColor(cell, color) {
  var row = cell.parentNode;
  var table = row.parentNode;
  for (var i = 0; i < table.rows.length; i++) {
    if (i == row.rowIndex) continue;
    table.rows[i].cells[cell.cellIndex].style.background = color;
  }
  for (var i = 0; i < row.cells.length; i++) {
    if (i == cell.cellIndex) continue;
    row.cells[i].style.background = color;
  }
}

function showPermissionDialog(link, object_id, role_id) {
  var cell = link.parentNode;
  var formCode = '';
  formCode = '<form action="resource-permission-edit" onsubmit="return submitForm(this, \'cell_'+object_id+'_'+role_id+'\')">';
  formCode += '<div>';
  formCode += '<input type="hidden" name="object_id" value="'+object_id+'" />';
  formCode += '<input type="hidden" name="role_id" value="'+role_id+'" />';
  formCode += '<input type="radio" name="privilege_'+object_id+'_'+role_id+'" value="none" /> None<br />';
  formCode += '<input type="radio" name="privilege_'+object_id+'_'+role_id+'" value="read" checked="checked" /> Read<br />';
  formCode += '<input type="radio" name="privilege_'+object_id+'_'+role_id+'" value="write" /> Write<br />';
  formCode += '<input type="submit" name="submit" value="Set" />';
  formCode += '</div>';
  formCode += '</form>';
  cell.innerHTML = formCode;
  return(false);
}

function editActivity(activity_id, run_id, title) {
  var cell = document.getElementById('activity_'+activity_id);
  var formCode = '';
  formCode = '<form action="activity-edit" onsubmit="return(submitForm(this, \'imsld_activity_tree\'))">';
  formCode += '<div class="activity_edit_form">';
  formCode += '<input type="hidden" name="activity_id" value="'+activity_id+'" />';
  formCode += '<input type="hidden" name="run_id" value="'+run_id+'" />';
  formCode += '<input type="text" name="title" value="' + title + '" size="20" />';
  formCode += '<input type="submit" name="submit" value="Set" />';
  formCode += '</div>';
  formCode += '</form>';
  cell.innerHTML = formCode;
  return(false);
}
