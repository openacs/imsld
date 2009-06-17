<if @visitors@ gt 1>
    (@visitors@  #imsld.users#)
</if>
<elseif @visitors@ gt 0>
    (@visitors@  #imsld.user#)
</elseif>
<else>
    (#imsld.No_users#)
</else>

<div class="activity_actions">
    
    <if @sort_order@ gt 0 and @bound_down@ gt 0>
      <a href="#" onclick="return(loadTree('@url_up@'))">
        <img src="/resources/imsld/arrow_up.png" alt="Up" >
      </a>
    </if>
    <if @sort_order@ lt @bound_down@>
      <a href="#" onclick="return(loadTree('@url_down@'))">
        <img src="/resources/imsld/arrow_down.png" alt="Down" >
      </a>
    </if>
    
    [
    <a href="#no" onclick="return(editActivity(@revision_id@, @run_id@, '@title@'))">
      <img src="/resources/acs-subsite/Edit16.gif" alt="#imsld.Edit#" >
    </a>
    <a href="#no" onclick="return(loadTree('@url_del@'))">
      <img src="/resources/acs-subsite/Delete16.gif" alt="#imsld.Delete#" >
    </a>
    ]
</div>
