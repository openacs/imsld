<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>

<if @imsld_info:rowcount@ eq 0>
    No information found in the imsmanifest.xml file. Nothing to do.
</if><else>
Pleas, confirm the information you are uploading
<blockquote>
<listtemplate name="imsld_info"></listtemplate>
</blockquote>
<formtemplate id=imsld_upload></formtemplate>
</else>

@msg;noquote@