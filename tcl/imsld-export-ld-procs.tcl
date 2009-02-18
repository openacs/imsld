namespace eval imsld::export::ld {}

###############################################################################
# Call this function to create imsld:learning-objectives label and content
###############################################################################
ad_proc -public imsld::export::ld::write_learning_objectives {
  -doc:required
  -learning_design:required
  -learning_objective_id:required
} {
  This proc is called to write learning-objectives label and content
} {
  if {$learning_objective_id != ""} {
    #Create learning-objectives label
    set learning_objectives [$doc createElement "imsld:learning-objectives"]
    $learning_design appendChild $learning_objectives

    #Write imsld:title label and content
    set imsld_title [$doc createElement "imsld:title"]
    $learning_objectives appendChild $imsld_title
    #Get title element
    db_1row get_title {select pretty_title from imsld_learning_objectives where learning_objective_id = cr_items.latest_revision and cr_items.item_id = :learning_objective_id}
    $imsld_title appendChild [$doc createTextNode "$pretty_title"]

    #Write imsld:item label and content
    set imsld_item [$doc createElement "imsld:item"]
    $learning_objectives appendChild $imsld_item
    #Get learning_objectives item data
    db_1row get_learning_objectives_info {select imsld_item_id, identifier, identifierref, is_visible_p from acs_rels, cr_items cr, imsld_items where :learning_objective_id = object_id_one and object_id_two = cr.item_id and cr.latest_revision = imsld_item_id}
    #Add attributes of imsld:item label
    $imsld_item setAttribute identifier $identifier
    $imsld_item setAttribute identifierref $identifierref
    if {$is_visible_p == "t"} {
      set is_visible "true"
    } else {
      set is_visible "false"
    }
    $imsld_item setAttribute isvisible $is_visible
    #Get title element
    db_1row get_title {select title from cr_revisions where revision_id = :imsld_item_id}
    #If title exists
    if {$title != ""} {
      #Write imsld:title label and content
      set imsld_title [$doc createElement "imsld:title"]
      $imsld_item appendChild $imsld_title
      $imsld_title appendChild [$doc createTextNode "$title"]
    }
  }
}

###############################################################################
# Call this function to create imsld:prerequisites label and content
###############################################################################
ad_proc -public imsld::export::ld::write_prerequisites {
  -doc:required
  -learning_design:required
  -prerequisite_id:required
} {
  This proc is called to write prerequisites label and content
} {
  if {$prerequisite_id != ""} {
    #Create prerequisites label
    set prerequisites [$doc createElement "imsld:prerequisites"]
    $learning_design appendChild $prerequisites

    #Write imsld:title label and content
    set imsld_title [$doc createElement "imsld:title"]
    $prerequisites appendChild $imsld_title
    #Get title element
    db_1row get_title {select pretty_title from imsld_prerequisites where prerequisite_id = cr_items.latest_revision and cr_items.item_id = :prerequisite_id}
    $imsld_title appendChild [$doc createTextNode "$pretty_title"]

    #Write imsld:item label and content
    set imsld_item [$doc createElement "imsld:item"]
    $prerequisites appendChild $imsld_item
    #Get learning_objectives item data
    db_1row get_prerequisites_info {select imsld_item_id, identifier, identifierref, is_visible_p from acs_rels, cr_items cr, imsld_items where :prerequisite_id = object_id_one and object_id_two = cr.item_id and cr.latest_revision = imsld_item_id}
    #Add attributes of imsld:item label
    $imsld_item setAttribute identifier $identifier
    $imsld_item setAttribute identifierref $identifierref
    if {$is_visible_p == "t"} {
      set is_visible "true"
    } else {
      set is_visible "false"
    }
    $imsld_item setAttribute isvisible $is_visible
    #Get title element
    db_1row get_title {select title from cr_revisions where revision_id = :imsld_item_id}
    #If title exists
    if {$title != ""} {
      #Write imsld:title label and content
      set imsld_title [$doc createElement "imsld:title"]
      $imsld_item appendChild $imsld_title
      $imsld_title appendChild [$doc createTextNode "$title"]
    }
  }
}

###############################################################################
# Call this function to create imsld:components label and content
###############################################################################
ad_proc -public imsld::export::ld::write_components {
  -doc:required
  -learning_design:required
  -imsld_id:required
} {
  This proc is called to write components label and content
} {
  #Create method label
  set components [$doc createElement "imsld:components"]
  $learning_design appendChild $components

  #Get component_id
  db_1row get_component_id {select component_id from imsld_components where imsld_id = cr_items.item_id and cr_items.latest_revision = :imsld_id}

  #Call proc to create roles
  imsld::export::ld::components::write_roles -doc $doc -components $components -component_id $component_id

  #Call proc to create properties
  imsld::export::ld::components::write_properties -doc $doc -components $components -component_id $component_id

  #Call proc to create activities
  imsld::export::ld::components::write_activities -doc $doc -components $components -component_id $component_id

  #Call proc to create environments
  imsld::export::ld::components::write_environments -doc $doc -components $components -component_id $component_id
}

###############################################################################
# Call this function to create imsld:method label and content
###############################################################################
ad_proc -public imsld::export::ld::write_method {
  -doc:required
  -learning_design:required
  -imsld_id:required
} {
  This proc is called to write method label and content
} {
  #Create method label
  set method [$doc createElement "imsld:method"]
  $learning_design appendChild $method

  db_1row get_imsld_item_id {select item_id from cr_items where latest_revision = :imsld_id}
  db_1row get_method_id {select item_id, complete_act_id, on_completion_id from cr_items, imsld_methods where :item_id = imsld_id and method_id = latest_revision}

  #Call proc to create conditions
  imsld::export::ld::method::write_conditions -doc $doc -method $method -method_id $item_id

  #Call proc to create play
  imsld::export::ld::method::write_play -doc $doc -method $method -method_id $item_id

  #Write complete-unit-of-learning if it exists
  if {[db_0or1row get_complete_unit_of_learning {select object_id_two from acs_rels where object_id_one = :item_id and rel_type = 'imsld_mp_completed_rel'}] == 1} {
    set complete_unit [$doc createElement "imsld:complete-unit-of-learning"]
    $method appendChild $complete_unit
    db_1row get_play_identifier {select identifier from imsld_plays where play_id = cr_items.latest_revision and cr_items.item_id = :object_id_two}
    set when_play_completed [$doc createElement "imsld:when-play-completed"]
    $complete_unit appendChild $when_play_completed
    #Add ref attibute
    $when_play_completed setAttribute ref $identifier
  }
}


