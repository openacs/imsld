<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>
  <property name="header_stuff">
<style  type="text/css">
td.element_title {
  background-color: #e0e0e0; 
  font-weight: bold;	 
}
td.element_value {
  background-color: #f0f0f0; 
  font-weight: bold;	 
}
</style>
</property>
   
<if @imsld_info:rowcount@ eq 0>
    #imsld.No#
</if>
<else>
    #imsld.lt_Please_confirm_the_in#

<listtemplate name="imsld_info"></listtemplate>

<formtemplate id=imsld_upload></formtemplate>
</else>

