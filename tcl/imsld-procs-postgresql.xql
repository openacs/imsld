<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.3</version></rdbms>

<fullquery name="imsld::rel_type_delete.drop_relationship_type">
      <querytext>
        select acs_rel_type__drop_type (:rel_type, 't');
      </querytext>
</fullquery>

<fullquery name="imsld::group_type_delete.drop_group_type">
      <querytext>
        select acs_object_type__drop_type(:group_type,'t');
      </querytext>
</fullquery>


</queryset>
