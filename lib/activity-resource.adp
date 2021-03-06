<switch @resource_type@>
    <case value="webcontent">      
      <multiple name="files">
        <if @li_mode_p;literal@ true>
          <li>
        </if>
        <a href="@files.href@" target="_blank"
          onclick="return(loadContent(this.href))" title="@files.title@">
          <img src="@img_src@" alt="@files.title@" title="@files.title@" >
          <if @li_mode_p;literal@ true>
            @files.title@
          </if>
        </a>
        <if @monitor_p;literal@ true>
        </if>
        <if @li_mode_p;literal@ true>
          </li>
        </if>
      </multiple>
    </case>
    <case value="imsldcontent">
      <multiple name="files">
        <if @li_mode_p;literal@ true>
          <li>
        </if>
        <a href="@files.href@" target="_blank"
          onclick="return(loadContent(this.href))" title="@files.file_name@">
          <img src="@img_src@" alt="@files.file_name@" title="@files.file_name@" >
          <if @li_mode_p;literal@ true>
            @files.file_name@
          </if>
        </a>
        <if @monitor_p;literal@ true>
        </if>
        <if @li_mode_p;literal@ true>
          </li>
        </if>
      </multiple>
    </case>
    <default>
      <if @acs_object_id@ ne "">
        <if @li_mode_p;literal@ true>
          <li>
        </if>
        <a href="@href@" target="_blank"
          onclick="return(loadContent(this.href))" title="@object_title@">
          <img src="@img_src@" alt="@object_title@" title="@object_title@" >
          <if @li_mode_p;literal@ true>
            @object_title@
          </if>
        </a>
        <if @monitor_p;literal@ true>
          
        </if>
        <if @li_mode_p;literal@ true>
          </li>
        </if>
      </if>
    </default>
</switch>
