<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>

<if @imsld_info:rowcount@ eq 0>
    #imsld.No#
</if>
<else>
    #imsld.lt_Please_confirm_the_in#
<blockquote>
<listtemplate name="imsld_info"></listtemplate>
</blockquote>
<formtemplate id=imsld_upload></formtemplate>
</else>

