--
-- IMS-LD Tree Support
--
-- @author jopez@inv.it.uc3m.es
-- @creation-date nov-2005
--

-- tree query support for imsld_items

create function imsld_items_insert_tr() returns trigger as '
declare
        v_parent_sk    		varbit default null;
        v_max_child_sortkey	varbit;
begin
        if new.parent_item_id is null then
 	        new.imsld_tree_sortkey := int_to_tree_key(new.imsld_item_id+1000);
        else
            SELECT imsld_tree_sortkey, tree_increment_key(imsld_max_child_sortkey)
  	        INTO v_parent_sk, v_max_child_sortkey
            FROM imsld_items
            WHERE imsld_item_id = (select live_revision from cr_items where item_id = new.parent_item_id)
            FOR UPDATE;

	        UPDATE imsld_items
	        SET imsld_max_child_sortkey = v_max_child_sortkey
	        WHERE imsld_item_id = new.parent_item_id;

            new.imsld_tree_sortkey := v_parent_sk || v_max_child_sortkey;
        end if;

	    new.imsld_max_child_sortkey := null;
        return new;
end;' language 'plpgsql';

create trigger imsld_items_insert_tr before insert 
on imsld_items for each row 
execute procedure imsld_items_insert_tr ();

