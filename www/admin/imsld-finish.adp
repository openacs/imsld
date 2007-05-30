<master>

<if @warning_flag@ not nil>
<p><b>#imsld.lt_Some_warnings_has_bee#</b></p>
    <ul>
    @warnings;noquote@
    </ul>
</if>

<if @error_flag@ not nil>
<p><b>#imsld.lt_Some_errors_has_been_#</b></p>
    <ul>@errors;noquote@</ul>
    <a href="@back@">#imsld.Go_back#</a>
    </if>
<else>

<hr>
<p>#imsld.lt_Are_all_the_students_#</p>

<p>#imsld.lt_If_you_are_not_sure_t# <a href="@back@">#imsld.go_back#</a></p>
<p>#imsld.lt_Otherwise_if_everthin# <a href="@confirm@">#imsld.Confirm#</a>.</p>
</else>



