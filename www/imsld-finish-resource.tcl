ad_page_contract {
    @author lfuente@it.uc3m.es
    @creation-date Jan 2006
} {
    file_url
    resource_item_id
}

db_1row get_resource_id {
    select resource_id
    from imsld_cp_resourcesi
    where item_id=:resource_item_id
}

#feedback must not be finished
if { ![
    db_0or1row is_feedback { select 1  
                            from acs_rels ar1,
                                 acs_rels ar2,
                                 imsld_feedback_rel_ext ifre 
                            where ifre.rel_id=ar1.rel_id and 
                                  ar1.object_id_two=ar2.object_id_one and 
                                  ar2.object_id_two=:resource_item_id 
    } ] } { 

    set prerequisites_list [db_list get_all_prerequisites {
        select prerequisite_id
        from imsld_imslds
    }]
    set objectives_list [db_list get_all_objectives {
        select learning_objective_id
        from imsld_imslds
    }]

#para no finalizar los prerequisitos y objetivos globales
    set identifier ""
    db_0or1row get_identifier_resource_id {
            select ar1.object_id_one as identifier 
            from acs_rels ar1, 
                 acs_rels ar2 
            where ar1.object_id_two=ar2.object_id_one 
                 and ar2.object_id_two=:resource_item_id;
    }

    if { [lsearch [concat $prerequisites_list $objectives_list] $identifier] != "-1" } {
        
    } else {
        imsld::finish_resource -resource_id $resource_id
    }
}
ad_returnredirect $file_url
