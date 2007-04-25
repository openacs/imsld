<?xml version="1.0"?>
<queryset>



<partialquery name="locpers_clause">
      <querytext>
	prop.type = 'locpers' and ins.run_id = :run_id and ins.party_id = :user_id
      </querytext>
</partialquery>

<partialquery name="loc_clause">
      <querytext>
             prop.type = 'loc' and ins.run_id = :run_id
      </querytext>
</partialquery>

<partialquery name="globpers_clause">
      <querytext>
             prop.type = 'globpers' and ins.party_id = :user_id
      </querytext>
</partialquery>

<partialquery name="glob_clause">
      <querytext>
	prop.type = 'global'
      </querytext>
</partialquery>

<partialquery name="locrole_clause">
      <querytext>
	prop.type = 'locrole' and ins.run_id = :run_id and ins.party_id = :role_instance_id
      </querytext>
</partialquery>

</queryset>

