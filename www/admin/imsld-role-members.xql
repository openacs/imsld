<?xml version="1.0"?>
<queryset>

	<fullquery name="get_group_name">
		<querytext>
        select group_name 
        from groups
        where group_id=:group_instance
        </querytext>
	</fullquery>
 
    <fullquery name="get_members_list">
		<querytext>
        select gmm.member_id
        from group_member_map gmm,
             acs_users_all aua
        where  aua.user_id=gmm.member_id 
               and gmm.group_id=:group_instance 
		</querytext>
	</fullquery>

    <fullquery name="get_not_members_list">
		<querytext>
        select aua.user_id
        from acs_users_all aua
        where user_id > 0
              and not (user_id in ([join $members_list ","]))
		</querytext>
	</fullquery>  

    
    <fullquery name="get_members_list_2">
		<querytext>
        select gmm.member_id
        from group_member_map gmm
        where group_id=:group_instance
              and container_id=:group_instance
		</querytext>
	</fullquery>

    
    <fullquery name="get_not_members_list_2">
		<querytext>
        select gmm.member_id
        from group_member_map gmm
        where container_id=:parent_instance
              and not (member_id in ([join $members_list ","]))
		</querytext>
	</fullquery>  
    
<fullquery name="get_users_list">
		<querytext>
        select dut.type as type,
               aua.username,
               aua.first_names,
               aua.last_name,
               aua.user_id
        from dotlrn_user_types dut,
             group_member_index gmi,
             acs_users_all aua
        where dut.group_id=gmi.group_id 
              and gmi.member_id=aua.user_id 
              and aua.user_id in ([join $members_list ","]);
		</querytext>
	</fullquery>

    <fullquery name="get_not_users_list">
		<querytext>
        select dut.type as type,
               aua.username,
               aua.first_names,
               aua.last_name,
               aua.user_id
        from dotlrn_user_types dut,
             group_member_index gmi,
             acs_users_all aua
        where dut.group_id=gmi.group_id 
              and gmi.member_id=aua.user_id 
              and aua.user_id in ([join $not_members_list ","]);
		</querytext>
	</fullquery>

    <fullquery name="has_role_parent_p">
		<querytext>
             select object_id_one as parent_instance
             from acs_rels 
             where object_id_two=:group_instance
                   and rel_type='composition_rel'
        </querytext>
	</fullquery>

    
</queryset>
