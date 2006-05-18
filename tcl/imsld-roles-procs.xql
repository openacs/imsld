<?xml version="1.0"?>
<queryset>
	<fullquery name="imsld::roles::create_instance.get_role_name">
		<querytext>
        select role_type,item_id as role_item_id  
        from imsld_rolesi 
        where role_id=:role_id
		</querytext>
	</fullquery>

    
    <fullquery name="imsld::roles::create_instance.get_create_new_p">
		<querytext>
        select create_new_p
        from imsld_roles 
        where role_id=:role_id
		</querytext>
	</fullquery>

 	<fullquery name="imsld::roles::get_subroles.get_subroles_list">
		<querytext>
        select iri1.role_id 
        from imsld_rolesi iri1,
             imsld_rolesi iri2
        where iri1.parent_role_id=iri2.item_id
              and iri2.role_id=:role_id
		</querytext>
	</fullquery>

<fullquery name="imsld::roles::create_instance.create_new_group">      
      <querytext>
             select acs_group__new(					  null,
													  'imsld_role_group',
													  now(),
													  :user_id,
													  :peeraddr,
													  null,
													  null,
													  :role_name,
                                                      null,
                                                      null
                                                      );
      </querytext>
</fullquery>

<fullquery name="imsld::roles::create_instance.name_already_exist">      
      <querytext>
        select count(*) as names_counter
        from groups
        where group_name like (:role_name || '%')
      </querytext>
</fullquery>


<fullquery name="imsld::roles::delete_instance.delete_group">      
      <querytext>
        select acs_group__delete(:group_to_remove);
      </querytext>
</fullquery>

<fullquery name="imsld::roles::delete_instance.check_children">      
      <querytext>
            select object_id_two as children_list
            from acs_rels 
            where object_id_one=:group_id
                  and rel_type='composition_rel'
      </querytext>
</fullquery>


 <fullquery name="imsld::roles::get_list_of_roles.roles_list">      
      <querytext>
        select ir.role_id
        from imsld_roles ir,
             imsld_imsldsi iii, 
             imsld_componentsi ici 
        where ir.component_id=ici.item_id 
              and ici.imsld_id=iii.item_id 
              and iii.imsld_id=:imsld_id
        order by ir.role_id
      </querytext>
</fullquery>


 <fullquery name="imsld::roles::get_depth.has_parent">      
      <querytext>
        select parent_role_id 
        from imsld_roles
        where role_id=:role_id
              and parent_role_id > 0
      </querytext>
</fullquery>


 <fullquery name="imsld::roles::get_roles_names.get_role_name">      
      <querytext>
        select title as name
        from imsld_rolesi
        where role_id=:role_item
      </querytext>
</fullquery>

 <fullquery name="imsld::roles::get_instantiated_groups.groups_from_role">      
      <querytext>
        select title as name
        from imsld_rolesi
        where role_id=:role_item
      </querytext>
</fullquery>

	<fullquery name="imsld::roles::get_role_info.get_imsld_role_info">
		<querytext>
        select max_persons,min_persons,create_new_p,match_persons_p
        from imsld_roles
        where role_id=:role_id
		</querytext>
	</fullquery>

    <fullquery name="imsld::roles::get_role_instances.get_community_related_groups">
		<querytext>
        select ar.object_id_two
        from acs_rels ar,
             acs_rels ar2,
             imsld_rolesi iri
        where ar.object_id_one=iri.item_id
              and ar.rel_type='imsld_role_group_rel'
              and ar.object_id_two=ar2.object_id_one
              and ar2.rel_type='imsld_roleinstance_club_rel'
              and ar2.object_id_two=:community_id
              and iri.role_id=:role_id
		</querytext>
	</fullquery>

	<fullquery name="imsld::roles::get_role_instances.get_related_groups">
		<querytext>
        select ar.object_id_two
        from acs_rels ar,
             imsld_rolesi iri
        where ar.object_id_one=iri.item_id
              and iri.role_id=:role_id
              and ar.rel_type='imsld_role_group_rel'
		</querytext>
	</fullquery>

	<fullquery name="imsld::roles::get_parent_role.get_parent_role">
		<querytext>
        select iri.role_id as parent_role 
        from imsld_rolesi iri,
             imsld_rolesi iri1 
        where iri1.parent_role_id=iri.item_id 
              and iri1.role_id=:role
        </querytext>
	</fullquery>


	<fullquery name="imsld::roles::get_parent_role_instance.get_parent_role_instance">
		<querytext>
        select object_id_one as parent_group_id
        from acs_rels 
        where object_id_two=:group_id
              and rel_type='composition_rel'
        </querytext>
	</fullquery>

	<fullquery name="imsld::roles::get_user_roles.get_user_roles_list">
		<querytext>
        select ir.role_id 
        from imsld_rolesi ir,
             group_member_map gmm, 
             acs_objects ao,
             acs_rels ar 
        where ao.object_id = gmm.group_id 
              and ao.object_type = 'imsld_role_group' 
              and ar.object_id_two = gmm.group_id 
              and ir.item_id = ar.object_id_one
              and gmm.member_id = :user_id
        </querytext>
	</fullquery>

	<fullquery name="imsld::roles::get_imsld_from_role.get_imsld">
		<querytext>
        select iii.imsld_id
        from imsld_imsldsi iii,
             imsld_roles ir,
             imsld_componentsi ici
        where iii.item_id = ici.imsld_id
              and ici.item_id = ir.component_id
              and ir.role_id = :role_id
        </querytext>
	</fullquery>


	<fullquery name="imsld::roles::get_role_instances.get_list_of_groups">
		<querytext>
        select ar1.object_id_two as group 
        from imsld_rolesi iri, 
             acs_rels ar1 
        where ar1.rel_type='imsld_role_group_rel' 
              and ar1.object_id_one=iri.item_id 
              and iri.role_id=:role_id 
        </querytext>
	</fullquery>

	<fullquery name="imsld::roles::get_role_instances.get_list_of_community_groups">
		<querytext>
        select object_id_one 
        from acs_rels 
        where rel_type='imsld_roleinstance_club_rel' 
              and object_id_one in ([join $groups_list ","])
              and object_id_two = :community_id
        </querytext>
	</fullquery>

    
</queryset>

