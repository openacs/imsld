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

	<fullquery name="imsld::roles::get_role_instances.get_related_groups">
		<querytext>
        select ar.object_id_two as groups
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
              and iri1.role_id=:role_id
        </querytext>
	</fullquery>





</queryset>
