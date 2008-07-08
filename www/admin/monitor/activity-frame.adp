<master src="../../../lib/imsld-master">
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>
  <property name="imsld_content_frame">1</property>

  <style type="text/css">.tabber{display:none;}</style>

  <div class="tabber">

  <div class="tabbertab">

  <h3>User activity</h3>

  <div class="frame-header">@frame_header@</div>
  
  <br />

  <div style="width:95%; margin-left:auto; ">
    <listtemplate name="related_users"></listtemplate>
  </div>

  </div>

  <if @type@ in learning support>

  <div class="tabbertab">

  <h3>Complete activity</h3>

  <div style="margin: 0 auto 10px auto; width: 80%;">
    <fieldset>
      <legend>Complete Activity</legend>
      <formtemplate id="complete">

        <div class="form-item-wrapper">
          <div>
            <input name="option" value="none"
              id="complete:elements:option:none" type="radio"
              onchange="enableFields(this)"<if @option@ eq "none"> checked</if> /> 
            <label for="complete:elements:option:none">
              None
            </label>
          </div>
          <div >
            <input name="option" value="choice"
            id="complete:elements:option:choice" type="radio"
            onchange="enableFields(this)"<if @option@ eq "choice"> checked</if> /> 
            <label for="complete:elements:option:choice">
              User choice
            </label>
          </div>
          <div >
            <input name="option" value="timelimit"
            id="complete:elements:option:timelimit" type="radio"
            onchange="enableFields(this)"<if @option@ eq timelimit> checked</if> /> 
            <label for="complete:elements:option:timelimit">
              Time limit
            </label>
            <div style="float:left; padding-right:5px; padding-left:20px;">
              <div>
                <label for="years">Yrs</label>
              </div> <!-- /form-label or /form-error -->
              <div>
                <formwidget id="years" />
              </div> <!-- /form-widget -->
            </div>
            <div style="float:left; padding-right:5px;">
              <div>
                <label for="months">Mons</label>
              </div> <!-- /form-label or /form-error -->
              <div>
                <formwidget id="months" />
              </div> <!-- /form-widget -->
            </div>
            <div style="float:left; padding-right:5px;">
              <div>
                <label for="days">Days</label>
              </div> <!-- /form-label or /form-error -->
              <div>
                <formwidget id="days" />
              </div> <!-- /form-widget -->
            </div>
            <div style="float:left; padding-right:5px;">
              <div>
                <label for="hours">Hrs</label>
              </div> <!-- /form-label or /form-error -->
              <div>
                <formwidget id="hours" />
              </div> <!-- /form-widget -->
            </div>
            <div style="float:left; padding-right:5px;">
              <div>
                <label for="minutes">Mins</label>
              </div> <!-- /form-label or /form-error -->
              <div>
                <formwidget id="minutes" />
              </div> <!-- /form-widget -->
            </div>
            <div style="float:left;">
              <div>
                <label for="seconds">Secs</label>
              </div> <!-- /form-label or /form-error -->
              <div>
                <formwidget id="seconds" />
              </div> <!-- /form-widget -->
            </div>
          </div>
          <div style="clear:both;">
            <input name="option" value="property"
            id="complete:elements:option:property" type="radio"
            onchange="enableFields(this)" <if
            @option@ eq property>
            checked</if>/> 
            <label for="complete:elements:option:property">
              When a property is set
            </label>
            <div style="float:left; padding-right:5px; padding-left:20px;">
              <div>
                <label for="property">Property</label>
              </div>
              <div>
                <formwidget id="property" />
              </div>
            </div>
            <div  style="float:none; padding-right:5px;
              padding-left:20px; clear:both;">
              <div>
                <label for="value">Value</label>
              </div> <!-- /form-label or /form-error -->
              <div>
                <formwidget id="value" value="@value_expression@" />
              </div>
            </div>
          </div>
        </div>
        <div class="form-button" style="clear:both; padding-top:10px;">
          <formwidget id="formbutton:ok">
        </div>
      </formtemplate>
    </fieldset>
        
  </div>

  </if>
  
  </div>
