#ad_page_contract { blank-master
#}

if { [template::util::is_nil title] } {
    set title [ad_conn instance_name]
}

if {![array exists doc]} {
    array set doc [list]
}

if { ![info exists header_stuff] } {
    set header_stuff ""
}

if { [string match /dotlrn/clubs/* [ad_conn url]] } {
    set css_url [parameter::get_from_package_key \
		     -package_key "theme-zen" \
		     -parameter "communityCssUrl" \
		     -default "/resources/theme-zen/css/color/purple.css"]
} elseif { [string match /dotlrn/classes/* [ad_conn url]] } {
    set css_url [parameter::get_from_package_key \
		     -package_key "theme-zen" \
		     -parameter "courseCssUrl" \
		     -default "/resources/theme-zen/css/color/green.css"]
} else {
    set css_url [parameter::get_from_package_key \
		     -package_key "theme-zen" \
		     -parameter "cssUrl" \
		     -default "/resources/theme-zen/css/color/blue.css"]
}

set local_header [subst {
    <meta http-equiv="content-type" content="text/html; charset=[ad_conn charset]">
    <meta name="robots" content="all">
    <meta name="keywords" content="accessibility, portals, elearning, design">
    <link rel="stylesheet" type="text/css" href="/resources/acs-subsite/default-master.css" media="screen">
    <link rel="stylesheet" type="text/css" href="/resources/theme-zen/css/main.css" media="screen">
    <link rel="stylesheet" type="text/css" href="/resources/theme-zen/css/print.css" media="print">
    <link rel="stylesheet" type="text/css" href="/resources/theme-zen/css/handheld.css" media="handheld">
    <link rel="stylesheet" type="text/css" href="$css_url" media="all">
    <link rel="alternate stylesheet" type="text/css" href="/resources/theme-zen/css/highContrast.css" title="highContrast">
    <link rel="alternate stylesheet" type="text/css" href="/resources/theme-zen/css/508.css" title="508">
    <link rel="stylesheet" href="/resources/imsld/example.css" TYPE="text/css" MEDIA="screen">
    <link rel="stylesheet" href="/resources/imsld/example-print.css" TYPE="text/css" MEDIA="print">
    <link rel="stylesheet" type="text/css" href="/resources/imsld/imsld.css" media="all">
}]

set custom_css [parameter::get -parameter "CustomCSS"]

if { $custom_css ne "" } {
    append local_header [subst {
	<link rel="stylesheet" type="text/css" href="${custom_css}" media="all">
    }]
}

append local_header {
    <script type="text/javascript" src="/resources/theme-zen/js/styleswitcher.js"></script>
    <script type="text/javascript" src="/resources/imsld/imsld.js"></script>
    <script type="text/javascript" src="/resources/imsld/tabber.js"></script>
    <script type="text/javascript" src="/resources/imsld/dynamicselect.js"></script>
}

set header_stuff "
  $local_header
  $header_stuff"

if {![info exists onload]} {
    set onload ""
}

set translations [list \
		      doc_type doc(type) \
		      title doc(title) \
		      header_stuff head \
		      onload body(onload) \
		     ]

foreach {from to} $translations {
    if {[info exists $from]} {
        set $to [set $from]
    } else {
        set $to {}
    }
}

if { ![template::util::is_nil focus] } {
    # Handle elements where the name contains a dot
    if { [regexp {^([^.]*)\.(.*)$} $focus match form_name element_name] } {
        lappend body(onload) "acs_Focus('${form_name}', '${element_name}');"
    }
}

if {[exists_and_not_null body_attributes]} {
    foreach body_attribute $body_attributes {
        if {[lsearch {
            id
            class
            onload 
            onunload 
            onclick 
            ondblclick 
            onmousedown 
            onmouseup 
            onmouseover 
            onmousemove 
            onmouseout 
            onkeypress 
            onkeydown 
            onkeyup
        } [lindex $body_attribute 0] >= 0]} {
            set body([lindex $body_attribute 0]) [lindex $body_attribute 1]
        } else {
            ns_log error "blank-compat: [ad_conn file] uses deprecated property body_attribute for [lindex $body_attribute 0] which is no longer supported!"
        }
    }
}

if {![template::multirow exists link]} {
    template::multirow create link rel type href title lang media
}

# DRB: this shouldn't really be in blank master, there should be some way for
# the templating package to associate a particular css file with pages that use
# particular form or list templates.  Therefore I'll put the hard-wired values
# in blank-compat for the moment.
multirow append link stylesheet text/css /resources/acs-templating/lists.css \
    "" [ad_conn language] all
multirow append link stylesheet text/css /resources/acs-templating/forms.css \
    "" [ad_conn language] all

if {![template::multirow exists script]} {
    template::multirow create script type src charset defer content
}

# 
# Add WYSIWYG editor content
#
global acs_blank_master__htmlareas acs_blank_master

if {[info exists acs_blank_master__htmlareas]
    && [llength $acs_blank_master__htmlareas] > 0} {
    # 
    # Add RTE scripts if we are using RTE
    #
    if {[info exists acs_blank_master(rte)]} {
        foreach htmlarea_id [lsort -unique $acs_blank_master__htmlareas] {
	    lappend body(onload) "acs_rteInit('${htmlarea_id}')"
        }
	
        template::multirow append script \
            "text/javascript" \
            "/resources/acs-templating/rte/richtext.js" 
    }
    
    # 
    # Add Xinha scripts if we are using Xinha
    #
    if {[info exists acs_blank_master(xinha)]} {
        set xinha_dir /resources/acs-templating/xinha-nightly/
        set xinha_plugins $acs_blank_master(xinha.plugins)
        set xinha_params ""
        set xinha_options $acs_blank_master(xinha.options)
        set xinha_lang [lang::conn::language]

        if {$xinha_lang ne "en" && $xinha_lang ne "de"} {
            set xinha_lang en
        }

        template::multirow append script "text/javascript" {} {} {} "
            _editor_url = \"$xinha_dir\";
            _editor_lang = \"$xinha_lang\";"
	
        template::multirow append script \
            "text/javascript" \
            "${xinha_dir}htmlarea.js"
    }
}

#ad_page_contract { blank-master
#}

if {[template::util::is_nil doc(type)]} { 
    set doc(type) {<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">}
}

if {[template::util::is_nil doc(charset)]} {
    set doc(charset) [ad_conn charset]
}

# The document language is always set from [ad_conn lang] which by default
# returns the language setting for the current user.  This is probably not a
# bad guess, but the rest of OpenACS must override this setting when
# appropriate and set the lang attribute of tags which differ from the language
# of the page.  Otherwise we are lying to the browser.
set doc(lang) [ad_conn language]

# AG: Markup in <title> tags doesn't render well.
set doc(title) [ns_striphtml $doc(title)]

if {![template::multirow exists meta]} {
    template::multirow create meta name content http_equiv scheme lang
}

if {![template::multirow exists script]} {
    template::multirow create script type src charset defer content
}
template::multirow append script text/javascript \
    /resources/acs-subsite/core.js "" "" ""

if {![template::multirow exists body_script]} {
    template::multirow create body_script type src charset defer content
}

# Concatenate the javascript event handlers for the body tag
if {[array exists body]} {
    foreach name [array names body -glob "on*"] {
	if {[llength $body($name)] > 0} {
	    append event_handlers " ${name}=\""
	    
	    foreach javascript $body($name) {
		append event_handlers "[string trimright $javascript "; "]; "
	    }

	    append event_handlers "\""
	}
    }
}

######################### lrn master

set user_id [ad_get_user_id] 
set untrusted_user_id [ad_conn untrusted_user_id]
set community_id [dotlrn_community::get_community_id]
set dotlrn_url [dotlrn::get_url]

#----------------------------------------------------------------------
# Display user messages
#----------------------------------------------------------------------

util_get_user_messages -multirow "user_messages"

# Get system name
set system_name [ad_system_name]
set system_url [ad_url]
if { [string equal [ad_conn url] "/"] } {
    set system_url ""
}

if {[dotlrn::user_p -user_id $user_id]} {
    set portal_id [dotlrn::get_portal_id -user_id $user_id]
}


# Set up some basic stuff
if { [ad_conn untrusted_user_id] == 0 } {
    set user_name {}
} else {
    set user_name [acs_user::get_element -user_id [ad_conn untrusted_user_id] \
		       -element name]
}

if {![exists_and_not_null title]} {
    set title [ad_system_name]
}

if {[empty_string_p [dotlrn_community::get_parent_community_id \
			 -package_id [ad_conn package_id]]]} {
    set parent_comm_p 0
} else {
    set parent_comm_p 1
}

set navbar ""
set subnavbar ""

if { [info exists text] } {
    set text [lang::util::localize $text]
}


# Focus
multirow create attribute key value

if { ![template::util::is_nil focus] } {
    # Handle elements wohse name contains a dot
    if { [regexp {^([^.]*)\.(.*)$} $focus match form_name element_name] } {
	
        # Add safety code to test that the element exists '
        append header_stuff "
          <script language=\"JavaScript\" type=\"text/javascript\">
            function acs_focus( form_name, element_name ) {
                if (document.forms == null) return;
                if (document.forms\[form_name\] == null) return;
                if (document.forms\[form_name\].elements\[element_name\] == null) return;
                if (document.forms\[form_name\].elements\[element_name\].type == 'hidden') return;

                document.forms\[form_name\].elements\[element_name\].focus();
            }
          </script>"
        template::multirow append \
	    attribute onload \
	    "javascript:acs_focus('${form_name}', '${element_name}')"
    }
}

