function withcontrolchange(img) {
  var withcontrol = img.nextSibling;
  withcontrol.style.display = withcontrol.style.display?"":"none";
  var title = withcontrol.nextSibling;
  title.style.display = title.style.display?"":"none";
}

  var divs = document.getElementsByTagName("div");
  for (var i = 0; i < divs.length; i++) {
    var withcontrol = divs[i];
    if (withcontrol.className.match(/\bwithcontrol\b/i)) {
      var title = withcontrol.getAttribute("title");
      var div = document.createElement("div");
      textnode = document.createTextNode(title);
      div.style.display = withcontrol.style.display?"":"none";
      div.appendChild(textnode);
      var img = document.createElement("img");
      img.setAttribute("src", "/resources/acs-templating/minus.gif");
      img.setAttribute("onClick", "withcontrolchange(this);");
      img.setAttribute("title", title);
      img.setAttribute("alt", title);
      withcontrol.parentNode.insertBefore(img, withcontrol);
      withcontrol.parentNode.insertBefore(div, withcontrol.nextSibling);
    }
  }
