<master>

<if @warning_flag@ not nil>
<p><b>Some warnings has been found</b></p>
    <ul>
    @warnings;noquote@
    </ul>
</if>

<if @error_flag@ not nil>
<p><b>Some errors has been found</b></p>
    <ul>@errors;noquote@</ul>
    <a href="@back@">Go back</a>
    </if>
<else>

<hr>
<p>Are all the students asigned to the proper roles? If you confirm now, no more changes will be acepted later.</p>

<p>If you are not sure that everything is OK, please <a href="@back@">go back</a></p>
<p>Otherwise, if everthing is OK and you are sure, please <a href="@confirm@">Confirm</a>.</p>
</else>


