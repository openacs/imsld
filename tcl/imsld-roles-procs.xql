<?xml version="1.0"?>
<queryset>
	<fullquery name="imsld::roles::create_instance.get_group_from_run">
		<querytext>
        select group_id as run_group_id  
        from imsld_run_users_group_ext 
        where run_id=:run_id
		</querytext>
	</fullquery>


<fullquery name="imsld::roles::create_instance.get_role_name">
		<querytext>
        select coalesce(title,role_type) as role_name,item_id as role_item_id  
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

<fullquery name="imsld::roles::create_instance.existing_instances">      
      <querytext>
        select gr.group_name 
        from groups gr, 
            acs_rels ar1, 
            acs_rels ar2, 
            imsld_run_users_group_ext iruge, 
            imsld_rolesi iri 
        where ar1.rel_type='imsld_roleinstance_run_rel' 
            and ar1.object_id_one=gr.group_id 
            and ar1.object_id_two=iruge.group_id 
            and iruge.run_id=:run_id
            and iri.role_id=:role_id
            and iri.item_id=ar2.object_id_one 
            and ar2.rel_type='imsld_role_group_rel' 
            and ar2.object_id_two=gr.group_id
        order by gr.group_name desc limit 1 
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
        select ir2.role_id as parent_role_id 
        from imsld_roles ir,
             imsld_rolesi ir2  
        where ir.role_id=:role_id
              and ir.parent_role_id > 0 
              and ir.parent_role_id=ir2.item_id
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

    <fullquery name="imsld::roles::get_role_instances.get_community_role_related_groups">
		<querytext>
        select ar.object_id_two
        from acs_rels ar,
             acs_rels ar2,
             imsld_rolesi iri,
             imsld_run_users_group_ext iruge
        where ar.object_id_one=iri.item_id
              and ar.rel_type='imsld_role_group_rel'
              and ar.object_id_two=ar2.object_id_one
              and ar2.rel_type='imsld_roleinstance_run_rel'
              and ar2.object_id_two=iruge.group_id
              and iruge.run_id=:run_id
              and iri.role_id=:role_id
		</querytext>
	</fullquery>

    <fullquery name="imsld::roles::get_role_instances.get_community_related_groups">
		<querytext>
        select ar.object_id_two
        from acs_rels ar,
             acs_rels ar2,
             imsld_rolesi iri,
             imsld_run_users_group_ext iruge
        where ar.object_id_one=iri.item_id
              and ar.rel_type='imsld_role_group_rel'
              and ar.object_id_two=ar2.object_id_one
              and ar2.rel_type='imsld_roleinstance_run_rel'
              and ar2.object_id_two=iruge.group_id
              and iruge.run_id=:run_id
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
		  from imsld_roles ir,
		       group_member_map gmm,
		       acs_objects ao,
		       acs_rels ar,
		       acs_rels ar2 ,
		       imsld_run_users_group_ext iruge,
		       cr_items cr
		  where ao.object_id=gmm.group_id 
		    and ao.object_type='imsld_role_group' 
		    and ar.object_id_one=gmm.group_id 
		    and ar.rel_type='imsld_roleinstance_run_rel' 
		    and gmm.member_id=:user_id
		    and iruge.group_id=ar.object_id_two 
		    and iruge.run_id=:run_id
		    and gmm.container_id = gmm.group_id
		    and ar2.object_id_two=gmm.group_id 
		    and ar2.rel_type='imsld_role_group_rel' 
		    and ar2.object_id_one=cr.item_id
		    and cr.live_revision=ir.role_id
        
        </querytext>
	</fullquery>

    <fullquery name="imsld::roles::get_user_roles.get_raw_user_roles_list">
		<querytext>
 select iri.role_id 
 from imsld_rolesi iri,
      group_member_map gmm,
      acs_objects ao,
      acs_rels ar,
      acs_rels ar2 
 where ao.object_id=gmm.group_id 
       and ao.object_type='imsld_role_group' 
       and ar.object_id_one=gmm.group_id 
       and ar.rel_type='imsld_roleinstance_run_rel' 
       and gmm.member_id=:user_id 
       and ar2.object_id_two=gmm.group_id 
       and ar2.rel_type='imsld_role_group_rel' 
       and ar2.object_id_one=iri.item_id

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

