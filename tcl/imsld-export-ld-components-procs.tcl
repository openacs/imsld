namespace eval imsld::export::ld::components {}

###############################################################################
# Call this function to create imsld:roles label and write its content
###############################################################################
ad_proc -public imsld::export::ld::components::write_roles {
  -doc:required
  -components:required
  -component_id:required
} {
  This proc is called to write all the information contained in imsld:roles label
} {
  #Create roles label
  set roles [$doc createElement "imsld:roles"]
  $components appendChild $roles

  set role ""
  #Create different roles
  db_multirow get_role get_role {select role_id, identifier, role_type, parent_role_id, create_new_p, match_persons_p, max_persons, min_persons, href from imsld_roles where component_id = cr_items.item_id and cr_items.latest_revision = :component_id} {
    #Create role
    if {$parent_role_id == ""} {
      set role [$doc createElement "imsld:$role_type"]
      $roles appendChild $role
    } else {
      set parent_role $role
      set role [$doc createElement "imsld:$role_type"]
      $parent_role appendChild $role
    }

    #Add attribute identifier
    if {$identifier != ""} {
      $role setAttribute identifier $identifier
    }

    #Add create-new attribute
    if {$create_new_p == "f"} {
      $role setAttribute create-new "not-allowed"
    }

    #Add match-persons attribute
    if {$create_new_p == "t"} {
      $role setAttribute match-persons "exclusively-in-roles"
    }

    #Add attribute min-persons
    if {$min_persons != ""} {
      $role setAttribute min-persons $min_persons
    }

    #Add attribute max-persons
    if {$max_persons != ""} {
      $role setAttribute max-persons $max_persons
    }

    #Add attribute href
    if {$href != ""} {
      $role setAttribute href $href
    }

    #Get element title
    db_1row get_title {select title from cr_revisions where revision_id = :role_id}
    if {$title != ""} {
      set imsld_title [$doc createElement "imsld:title"]
      $role appendChild $imsld_title
      $imsld_title appendChild [$doc createTextNode "$title"]
    }

    #Call proc to write role information
    imsld::export::ld::components::write_role_information -doc $doc -role $role -role_id $role_id -title $title
  }
}

###############################################################################
# Call this function to create imsld:information label and write its content
###############################################################################
ad_proc -public imsld::export::ld::components::write_role_information {
  -doc:required
  -role:required
  -role_id:required
  -title:required
} {
  This proc is called to write all the information contained in 
   imsld:information label which is contained in imsld:role
} {
  set aux 0
  #Get role information item data
  db_multirow get_role_info get_role_info {select imsld_item_id, identifier, identifierref, is_visible_p from acs_rels, cr_items cr1, cr_items cr2, imsld_items where :role_id = cr1.latest_revision and cr1.item_id = object_id_one and object_id_two = cr2.item_id and cr2.latest_revision = imsld_item_id} {
    #If the information label doesn't exist, create it
    if {$aux == 0} {
      set information [$doc createElement "imsld:information"]
      $role appendChild $information
      set aux 1
      #If title exists
      if {$title != ""} {
        #Write imsld:title label and content
        set imsld_title [$doc createElement "imsld:title"]
        $information appendChild $imsld_title
        $imsld_title appendChild [$doc createTextNode "$title"]
      }
    }
    #Write imsld:item label and content
    set imsld_item [$doc createElement "imsld:item"]
    $information appendChild $imsld_item
    #Add attributes of imsld:item label
    if {$identifier != ""} {
      $imsld_item setAttribute identifier $identifier
    }
    #Check if the reference is of a xowiki page, if it is the case, fill identifierref with resource_(resource_number)
    if {[string first "item_" $identifier] == 0} {
      set identifierref "resource_[string range $identifier [expr [string first "_" $identifier]+1] end]"
    }
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
# Call this function to create imsld:properties label and write its content
###############################################################################
ad_proc -public imsld::export::ld::components::write_properties {
  -doc:required
  -components:required
  -component_id:required
} {
  This proc is called to write all the information contained in imsld:properties label
} {
  set aux 0
  #Get properties
  db_multirow get_properties get_properties {select * from imsld_properties where component_id = cr_items.item_id and cr_items.latest_revision = :component_id} {
    #Create properties label if it has not been created before
    if {$aux == 0} {
      set aux 1
      #Create properties label
      set properties [$doc createElement "imsld:properties"]
      $components appendChild $properties 
    }
    if {$type == "loc"} {
      #Create loc-property label
      set property [$doc createElement "imsld:loc-property"]
      $properties appendChild $property
    } elseif {$type == "locpers"} {
      #Create locpers-property label
      set property [$doc createElement "imsld:locpers-property"]
      $properties appendChild $property
    } elseif {$type == "locrole"} {
      #Create locrole-property label
      set property [$doc createElement "imsld:locrole-property"]
      $properties appendChild $property
    } elseif {$type == "globpers"} {
      #Create globpers-property label
      set property [$doc createElement "imsld:globpers-property"]
      $properties appendChild $property
    } elseif {$type == "global"} {
      #Create glob-property label
      set property [$doc createElement "imsld:glob-property"]
      $properties appendChild $property
    }

    #Write all associated information to property
    #Add attribute identifier
    if {$identifier != ""} {
      $property setAttribute identifier $identifier
    }

    #Get title element
    db_1row get_title {select title from cr_revisions where revision_id = :property_id}
    #If title exists
    if {$title != ""} {
      #Write imsld:title label and content
      set imsld_title [$doc createElement "imsld:title"]
      $property appendChild $imsld_title
      $imsld_title appendChild [$doc createTextNode "$title"]
    }

    #Create imsld:datatype label
    set imsld_datatype [$doc createElement "imsld:datatype"]
    $property appendChild $imsld_datatype
    #Add attribute datatype
    $property setAttribute datatype $datatype

    #If initial-value exists
    if {$initial_value != ""} {
      #Create imsld:initial-value label
      set imsld_initialvalue [$doc createElement "imsld:initial-value"]
      $property appendChild $imsld_initialvalue
      #Create text node
      $imsld_initialvalue appendChild [$doc createTextNode "$initial_value"]
    }

    #Call proc to write restrictions
    imsld::export::ld::components::write_restrictions -doc $doc -property $property -property_id $property_id
  }

  #Get property-groups
  db_multirow get_property_groups get_property_groups {select * from imsld_property_groups where component_id = :component_id} {
    #Create imsld:property-group label
    set property_group [$doc createElement "imsld:property-group"]
    $properties appendChild $property_group
    #Add attribute identifier
    if {$identifier != ""} {
      $property_group setAttribute identifier $identifier
    }

    #Get title element
    db_1row get_title {select title from cr_revisions where revision_id = :property_group_id}
    #If title exists
    if {$title != ""} {
      #Write imsld:title label and content
      set imsld_title [$doc createElement "imsld:title"]
      $property_group appendChild $imsld_title
      $imsld_title appendChild [$doc createTextNode "$title"]
    }
    #Call proc to write property refs
    imsld::export::ld::components::write_property_refs -doc $doc -property_group $property_group -property_group_id $property_group_id
  }
}

###############################################################################
# Call this function to create imsld:properties label and write its content
###############################################################################
ad_proc -public imsld::export::ld::components::write_restrictions {
  -doc:required
  -property:required
  -property_id:required
} {
  This proc is called to write all the information contained in imsld:restriction label
} {
  #Get restrictions
  db_multirow get_restrictions get_restrictions {select * from imsld_restrictions where property_id = cr_items.item_id and cr_items.latest_revision = :property_id order by restriction_id asc} {
    #Create imsld:restriction label
    set imsld_restriction [$doc createElement "imsld:restriction"]
    $property appendChild $imsld_restriction
    #Add attribute restriction-type
    $imsld_restriction setAttribute "restriction-type" $restriction_type
    #Create text node
    $imsld_restriction appendChild [$doc createTextNode "$value"] 
  }
}

###############################################################################
# Call this function to create imsld:property-ref label and write its content
###############################################################################
ad_proc -public imsld::export::ld::components::write_property_refs {
  -doc:required
  -property_group:required
  -property_group_id:required
} {
  This proc is called to write all the information contained in imsld:property_ref
   and imsld:property-group-ref labels
} {
  #Get property-refs
  db_multirow get_property_refs get_property_refs {select identifier from imsld_properties, cr_items cr1, cr_items cr2 where :property_group_id = cr1.latest_revision and cr1.item_id = acs_rels.object_id_one and acs_rels.object_id_two = cr2.item_id and cr2.latest_revision = property_id and acs_rels.rel_type = 'imsld_gprop_prop_rel'} {
    #Create imsld:property-ref label
    set property_ref [$doc createElement "imsld:property-ref"]
    $property_group appendChild $property_ref
    #Add attribute ref
    $property_ref setAttribute ref $identifier
  }

  #Get property-group-refs
  db_multirow get_property_refs get_property_refs {select identifier from imsld_property_groups, cr_items cr1, cr_items cr2 where :property_group_id = cr1.latest_revision and cr1.item_id = acs_rels.object_id_one and acs_rels.object_id_two = cr2.item_id and cr2.latest_revision = property_group_id and acs_rels.rel_type = 'imsld_gprop_gprop_rel'} {
    #Create imsld:property-group label
    set property_ref [$doc createElement "imsld:property-group-ref"]
    $property_group appendChild $property_ref
    #Add attribute ref
    $property_ref setAttribute ref $identifier
  }
}

###############################################################################
# Call this function to create imsld:activities label and write its content
###############################################################################
ad_proc -public imsld::export::ld::components::write_activities {
  -doc:required
  -components:required
  -component_id:required
} {
  This proc is called to write all the information contained in imsld:activities label
} {
  #Create activities label
  set activities [$doc createElement "imsld:activities"]
  $components appendChild $activities

  #Create learning activity
  db_multirow get_learning_activity get_learning_activity {select activity_id, identifier,activity_description_id, is_visible_p, complete_act_id, on_completion_id, learning_objective_id, prerequisite_id, parameters from imsld_learning_activities where component_id = cr_items.item_id and cr_items.latest_revision = :component_id} {
    #Create learning-activity label
    set la [$doc createElement "imsld:learning-activity"]
    $activities appendChild $la
    #Add attribute identifier
    if {$identifier != ""} {
      $la setAttribute identifier $identifier
    }
    #Add parameters if ther are parameters
    if {$parameters != ""} {
      $la setAttribute parameters $parameters
    }
    #Format is_visible_p to add attribute
    if {$is_visible_p == "t"} {
      set is_visible "true"
    } else {
      set is_visible "false"
    }
    $la setAttribute isvisible $is_visible

    #Get title element
    db_1row get_title {select title from cr_revisions where revision_id = :activity_id}
    if {$title != ""} {
      set imsld_title [$doc createElement "imsld:title"]
      $la appendChild $imsld_title
      $imsld_title appendChild [$doc createTextNode "$title"]
    }

    #Call proc to write environment-ref in case it exists
    imsld::export::ld::components::write_environment_ref -doc $doc -learning_activity $la -learning_activity_id $activity_id

    #Call proc to write learning-objectives
    if {$learning_objective_id != ""} {
      imsld::export::ld::components::write_learning_objectives -doc $doc -learning_activity $la -learning_objective_id $learning_objective_id
    }
    #Call proc to write prerequisites
    imsld::export::ld::components::write_prerequisites -doc $doc -learning_activity $la -prerequisite_id $prerequisite_id

    #Call proc to write activity description
    imsld::export::ld::components::write_activity_description -doc $doc -learning_activity $la -activity_description_id $activity_description_id

    #Create on-completion label in case it is necessary
    if {$on_completion_id != ""} {
      #Call proc to write imsld:on-completion label
      imsld::export::ld::components::write_on_completion -doc $doc -learning_activity $la -on_completion_id $on_completion_id
    }
    #Create complete-activity label in case it is necessary
    if {$complete_act_id != ""} {
      #Call proc to write imsld:complete-activity label
      imsld::export::ld::components::write_complete_activity -doc $doc -learning_activity $la -complete_act_id $complete_act_id
    }
  }

  #Create support activity
  db_multirow get_support_activity get_support_activity {select activity_id, identifier,activity_description_id, is_visible_p, complete_act_id, on_completion_id from imsld_support_activities where component_id = cr_items.item_id and cr_items.latest_revision = :component_id} {
    #Create learning-activity label
    set sa [$doc createElement "imsld:support-activity"]
    $activities appendChild $sa
    #Add attribute identifier
    if {$identifier != ""} {
      $sa setAttribute identifier $identifier
    }
    #Format is_visible_p to add attribute
    if {$is_visible_p == "t"} {
      set is_visible "true"
    } else {
      set is_visible "false"
    }
    $sa setAttribute isvisible $is_visible

    #Get title element
    db_1row get_title {select title from cr_revisions where revision_id = :activity_id}
    if {$title != ""} {
      set imsld_title [$doc createElement "imsld:title"]
      $sa appendChild $imsld_title
      $imsld_title appendChild [$doc createTextNode "$title"]
    }

    #Call proc to write activity description
    imsld::export::ld::components::write_activity_description -doc $doc -learning_activity $sa -activity_description_id $activity_description_id

    #Create on-completion label in case it is necessary
    if {$on_completion_id != ""} {
      #Call proc to write imsld:on-completion label
      imsld::export::ld::components::write_on_completion -doc $doc -learning_activity $sa -on_completion_id $on_completion_id
    }
    #Create complete-activity label in case it is necessary
    if {$complete_act_id != ""} {
      #Call proc to write imsld:complete-activity label
      imsld::export::ld::components::write_complete_activity -doc $doc -learning_activity $sa -complete_act_id $complete_act_id
    }
  }

  #Get activity estructures
  db_multirow get_activity_structures get_activity_structures {select structure_id, identifier, number_to_select, structure_type, sort from imsld_activity_structures where component_id = cr_items.item_id and cr_items.latest_revision = :component_id} {
    set activity_structure [$doc createElement "imsld:activity-structure"]
    $activities appendChild $activity_structure
    #Set activity-structure attributes
    if {$identifier != ""} {
      $activity_structure setAttribute identifier $identifier
    }
    $activity_structure setAttribute sort $sort
    if {$number_to_select != ""} {
      $activity_structure setAttribute "number-to-select" $number_to_select
    }
    if {$structure_type != ""} {
      $activity_structure setAttribute "structure-type" [string trim $structure_type]
    }

    #Get title element
    db_1row get_title {select title from cr_revisions where revision_id = :structure_id}
    if {$title != ""} {
      set imsld_title [$doc createElement "imsld:title"]
      $activity_structure appendChild $imsld_title
      $imsld_title appendChild [$doc createTextNode "$title"]
    }

    #Call proc to fill activity-structure with learning-activity-refs
    imsld::export::ld::components::write_la_ref -doc $doc -activity_structure $activity_structure -structure_id $structure_id

  }
}

###############################################################################
# Call this function to create imsld:environment-ref label and write its
# content
###############################################################################
ad_proc -public imsld::export::ld::components::write_environment_ref {
  -doc:required
  -learning_activity:required
  -learning_activity_id:required
} {
  db_multirow get_environment get_environment {select object_id_two from acs_rels, cr_items where object_id_one = item_id and latest_revision = :learning_activity_id and rel_type = 'imsld_la_env_rel'} {
    #Get environment-ref identifier
    db_1row get_environment_ref {select identifier from imsld_environments, cr_items where :object_id_two = item_id and latest_revision = environment_id}
    #Create environment-ref label
    set environment_ref [$doc createElement "imsld:environment-ref"]
    $learning_activity appendChild $environment_ref
    #Set activity-structure attributes
    $environment_ref setAttribute ref $identifier
  }
}

###############################################################################
# Call this function to create imsld:learning-objectives label and write its
# content
###############################################################################
ad_proc -public imsld::export::ld::components::write_learning_objectives {
  -doc:required
  -learning_activity:required
  -learning_objective_id:required
} {
  This proc is called to write all the information contained in 
   imsld:learning-objective label
} {
  #Call proc that fills learning-objectives (it is used in learning-design)
  imsld::export::ld::write_learning_objectives -doc $doc -learning_design $learning_activity -learning_objective_id $learning_objective_id
}

###############################################################################
# Call this function to create imsld:prerequisites label and write its
# content
###############################################################################
ad_proc -public imsld::export::ld::components::write_prerequisites {
  -doc:required
  -learning_activity:required
  -prerequisite_id:required
} {
  This proc is called to write all the information contained in 
   imsld:prerequisites label
} {
  #Call proc that fills prerequisites (it is used in learning-design)
  imsld::export::ld::write_prerequisites -doc $doc -learning_design $learning_activity -prerequisite_id $prerequisite_id
}

###############################################################################
# Call this function to create imsld:activity-description label and write its
# content
###############################################################################
ad_proc -public imsld::export::ld::components::write_activity_description {
  -doc:required
  -learning_activity:required
  -activity_description_id:required
} {
  This proc is called to write all the information contained in 
   imsld:activity-description label
} {
  #Create activity-description label
  set activity_description [$doc createElement "imsld:activity-description"]
  $learning_activity appendChild $activity_description

  #Get element title
  db_1row get_title {select title from cr_revisions where item_id = :activity_description_id}
  #If it has a title, then write it
  if {$title != ""} {
    set imsld_title [$doc createElement "imsld:title"]
    $activity_description appendChild $imsld_title
    $imsld_title appendChild [$doc createTextNode "$title"]
  }

  #Get learning_objectives item data
  db_multirow get_activity_description_info get_activity_description_info {select imsld_item_id, identifier, identifierref, is_visible_p from acs_rels, cr_items cr, imsld_items where :activity_description_id = object_id_one and object_id_two = cr.item_id and cr.latest_revision = imsld_item_id} {
    #Write imsld:item label and content
    set imsld_item [$doc createElement "imsld:item"]
    $activity_description appendChild $imsld_item
    #Add attributes of imsld:item label
    if {$identifier != ""} {
      $imsld_item setAttribute identifier $identifier
    }
    #Check if the reference is of a xowiki page, if it is the case, fill identifierref with resource_(resource_number)
    if {[string first "item_" $identifier] == 0} {
      set identifierref "resource_[string range $identifier [expr [string first "_" $identifier]+1] end]"
    }

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
# Call this function to create imsld:on-completion label and write its
# content
###############################################################################
ad_proc -public imsld::export::ld::components::write_on_completion {
  -doc:required
  -learning_activity:required
  -on_completion_id:required
} {
  This proc is called to write all the information contained in 
   imsld:on-completion label
} {
  #Create on-completion label
  set on_completion [$doc createElement "imsld:on-completion"]
  $learning_activity appendChild $on_completion
  
  #Get on-completion data
  db_1row get_data {select feedback_title, change_property_value_xml from imsld_on_completion where on_completion_id = cr_items.latest_revision and cr_items.item_id = :on_completion_id}

  if {$change_property_value_xml == ""} {

    if {$feedback_title != ""} {
      #Create feedback-description label
      set feedback_description [$doc createElement "imsld:feedback-description"]
      $on_completion appendChild $feedback_description
      #Write imsld:title label and content
      set imsld_title [$doc createElement "imsld:title"]
      $feedback_description appendChild $imsld_title
      #Write title element
      $imsld_title appendChild [$doc createTextNode "$feedback_title"]
    }

    #If there is an activity description associated, then write it
    if {[db_0or1row get_activity_description_info {select imsld_item_id, identifier, identifierref, is_visible_p from acs_rels, cr_items cr, imsld_items where :on_completion_id = object_id_one and object_id_two = cr.item_id and cr.latest_revision = imsld_item_id}] == 1} {
      #Write imsld:item label and content
      set imsld_item [$doc createElement "imsld:item"]
      $feedback_description appendChild $imsld_item
    
      #Add attributes of imsld:item label
      if {$identifier != ""} {
        $imsld_item setAttribute identifier $identifier
      }
      #Check if the reference is of a xowiki page, if it is the case, fill identifierref with resource_(resource_number)
      if {[string first "item_" $identifier] == 0} {
        set identifierref "resource_[string range $identifier [expr [string first "_" $identifier]+1] end]"
      }
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

    #Write change-property-values
    if {$change_property_value_xml != ""} {
      #First, create the new document
      set change_prop_val [dom parse $change_property_value_xml]
      #Get root element of the document
      set root [$change_prop_val documentElement]
      $on_completion appendChild [$root firstChild]
    }
  }

  #If there is a notification associated
  db_multirow get_notifications get_notifications {select notification_id, activity_id, subject from imsld_notifications, acs_rels, cr_items cr1 where :on_completion_id = object_id_one and rel_type = 'imsld_on_comp_notif_rel' and object_id_two = cr1.item_id and cr1.latest_revision = notification_id} {
    #Write imsld:notification label and content
    set imsld_notification [$doc createElement "imsld:notification"]
    $on_completion appendChild $imsld_notification

    #Get email information in case the notification is of this type
    db_multirow get_email_data get_email_data {select send.role_id, username_property_id, identifier from imsld_send_mail_data send, imsld_properties, acs_rels, cr_items cr1, cr_items cr2, cr_items cr3 where :notification_id = cr1.latest_revision and cr1.item_id = object_id_one and object_id_two = cr2.item_id and cr2.latest_revision = data_id and email_property_id = cr3.item_id and cr3.latest_revision = property_id} {
      #Write imsld:email-data label and content
      set imsld_email_data [$doc createElement "imsld:email-data"]
      $imsld_notification appendChild $imsld_email_data
      #Write email-property-ref attribute
      $imsld_email_data setAttribute email-property-ref $identifier
      lappend email_data [list $imsld_email_data $role_id]
    }

    #Get number of imsld:email-data elements  
    set stop [llength $email_data]
    #Loop for each element in the list
    for {set i 0} {$i < $stop} {incr i} {
      #Get information from the list
      set element [lindex $email_data $i]
      set imsld_email_data [lindex $element 0]
      set role_id [lindex $element 1]
      #Write role-ref
      if {[db_0or1row get_role {select identifier from imsld_roles, cr_items where :role_id = item_id and latest_revision = role_id}] == 1} {
        #Write imsld:role-ref label and content
        set imsld_role_ref [$doc createElement "imsld:role-ref"]
        $imsld_email_data appendChild $imsld_role_ref
        #Write ref attribute
        $imsld_role_ref setAttribute ref $identifier
      }
    }

    #Write learning-activity-ref if it exists
    if {$activity_id != ""} {
      db_1row get_activity_ref {select identifier from imsld_learning_activities, cr_items where :activity_id = item_id and latest_revision = activity_id}
      #Write imsld:role-ref label and content
      set la_ref [$doc createElement "imsld:learning-activity-ref"]
      $imsld_notification appendChild $la_ref
      #Write ref attribute
      $la_ref setAttribute ref $identifier
    }

    #If there is a subject, write it
    if {$subject != ""} {
      set imsld_subject [$doc createElement "imsld:subject"]
      $imsld_notification appendChild $imsld_subject
      $imsld_subject appendChild [$doc createTextNode "$subject"]
    }
  }
}

###############################################################################
# Call this function to create imsld:complete-activity label and write its
# content
###############################################################################
ad_proc -public imsld::export::ld::components::write_complete_activity {
  -doc:required
  -learning_activity:required
  -complete_act_id:required
} {
  This proc is called to write all the information contained in 
   imsld:complete-activity label
} {
  #Create complete-act label
  set complete_activity [$doc createElement "imsld:complete-activity"]
  $learning_activity appendChild $complete_activity

  #Get complete-activity information and write it
  db_1row get_complete_activity {select * from imsld_complete_acts where complete_act_id = cr_items.latest_revision and cr_items.item_id = :complete_act_id}
  #If activity ends by user choice
  if {$user_choice_p == "t"} {
    set user_choice [$doc createElement "imsld:user-choice"]
    $complete_activity appendChild $user_choice
  }

  #If activity ends
  if {$time_string != ""} {
    set time_limit [$doc createElement "imsld:time-limit"]
    $complete_activity appendChild $time_limit
    $time_limit appendChild [$doc createTextNode "$time_string"]
  }

  #If activity has when-property-value-is-set
  if {$when_prop_val_is_set_xml != ""} {
    #Write when-property-value-is-set
    #First, create the new document
    set when_prop_val [dom parse $when_prop_val_is_set_xml]
    #Get root element of the document
    set root [$when_prop_val documentElement]
    $complete_activity appendChild $root
  }

  ###################################
  # This is not implemented
  ###################################
  #time_in_seconds, when_last_act_completed_p, when_condition_true, time_property_id
}

###############################################################################
# Call this function to create imsld:learning-activity-ref label and write its
# content
###############################################################################
ad_proc -public imsld::export::ld::components::write_la_ref {
  -doc:required
  -activity_structure:required
  -structure_id:required
} {
  This proc is called to write all the information contained in 
   imsld:learning-activity-ref label
} {
  #Get learning activity refs to create new learning-activity-ref label
  db_multirow get_learning_activity_refs get_learning_activity_refs {select acs.object_id_two from acs_rels acs, imsld_as_la_rels imsld where acs.object_id_one = cr_items.item_id and cr_items.latest_revision = :structure_id and acs.rel_id = imsld.rel_id order by imsld.sort_order asc} {
    #Create learning-activity_ref label
    set la_ref [$doc createElement "imsld:learning-activity-ref"]
    $activity_structure appendChild $la_ref
    db_1row get_la_identifier {select identifier from imsld_learning_activities where activity_id = cr_items.latest_revision and cr_items.item_id = :object_id_two}
    #Add identifier attribute
    if {$identifier != ""} {
      $la_ref setAttribute ref $identifier
    }
  }
}

###############################################################################
# Call this function to create imsld:environments label and write its content
###############################################################################
ad_proc -public imsld::export::ld::components::write_environments {
  -doc:required
  -components:required
  -component_id:required
} {
  This proc is called to write all the information contained in imsld:environments label
} {
  set aux 0
  #Create environment
  db_multirow get_environment get_environment {select environment_id, identifier from imsld_environments where component_id = cr_items.item_id and cr_items.latest_revision = :component_id} {
    #Create environments label if it doesn't exist before
    if {$aux == 0} {
      set environments [$doc createElement "imsld:environments"]
      $components appendChild $environments
      set aux 1
    }
    imsld::export::ld::components::write_environment -doc $doc -environments $environments -environment_id $environment_id -identifier $identifier
  }
}

###############################################################################
# Call this function to create imsld:environment label and write its content
###############################################################################
ad_proc -public imsld::export::ld::components::write_environment {
  -doc:required
  -environments:required
  -environment_id:required
  -identifier:required
} {
  This proc is called to write all the information contained in
 imsld:environment label
} {
  #Create environment label
  set environment [$doc createElement "imsld:environment"]
  $environments appendChild $environment
  #Add attribute identifier
  if {$identifier != ""} {
    $environment setAttribute identifier $identifier
  }

  #Get element title
  db_1row get_title {select title from cr_revisions where revision_id = :environment_id}
  if {$title != ""} {
    set imsld_title [$doc createElement "imsld:title"]
    $environment appendChild $imsld_title
    $imsld_title appendChild [$doc createTextNode "$title"]
  }

  #If the current environment has one or more learning_objects, then write them
  db_multirow get_learning_objects get_learning_objects {select learning_object_id, identifier from imsld_learning_objects where environment_id = cr_items.item_id and cr_items.latest_revision = :environment_id} {
    #Write imsld:learning-object label and content
    set learning_object [$doc createElement "imsld:learning-object"]
    $environment appendChild $learning_object
    #Add attribute identifier
    if {$identifier != ""} {
      $learning_object setAttribute identifier $identifier
    }

    #Get title element
    db_1row get_title {select title from cr_revisions where revision_id = :learning_object_id}
    #If title exists
    if {$title != ""} {
      #Write imsld:title label and content
      set imsld_title [$doc createElement "imsld:title"]
      $learning_object appendChild $imsld_title
      $imsld_title appendChild [$doc createTextNode "$title"]
    }

    #Get items associated to the learning_object
    db_foreach get_learning_object_item {select imsld_item_id, identifier, identifierref, is_visible_p, title from acs_rels, cr_items cr1, cr_items cr2, imsld_items, cr_revisions where :learning_object_id = cr1.latest_revision and cr1.item_id = object_id_one and object_id_two = cr2.item_id and cr2.latest_revision = imsld_item_id and revision_id = imsld_item_id} {
      #Write imsld:item label and content
      set imsld_item [$doc createElement "imsld:item"]
      $learning_object appendChild $imsld_item
      #Add attributes of imsld:item label
      if {$identifier != ""} {
        $imsld_item setAttribute identifier $identifier
      }
      #Check if the reference is of a xowiki page, if it is the case, fill identifierref with resource_(resource_number)
      if {[string first "item_" $identifier] == 0} {
        set identifierref "resource_[string range $identifier [expr [string first "_" $identifier]+1] end]"
      }		
      $imsld_item setAttribute identifierref $identifierref
      if {$is_visible_p == "t"} {
        set is_visible "true"
      } else {
        set is_visible "false"
      }
      $imsld_item setAttribute isvisible $is_visible
      #If title exists
      if {$title != ""} {
        #Write imsld:title label and content
        set imsld_title [$doc createElement "imsld:title"]
        $imsld_item appendChild $imsld_title
        $imsld_title appendChild [$doc createTextNode "$title"]
      }
    }
  }



  #If the current environment has one or more services, then write them
  db_multirow get_services get_services {select service_id, identifier, is_visible_p, service_type from imsld_services where environment_id = cr_items.item_id and cr_items.latest_revision = :environment_id} {

    #Write imsld:service label and content
    set imsld_service [$doc createElement "imsld:service"]
    $environment appendChild $imsld_service
    #Add attributes of imsld:service label
    if {$identifier != ""} {
      $imsld_service setAttribute identifier $identifier
    }
    if {$is_visible_p == "t"} {
      set is_visible "true"
    } else {
      set is_visible "false"
    }
    $imsld_service setAttribute isvisible $is_visible

    if {$service_type == "conference"} {
      #If the service is of type conference, get conference data and write it
      db_1row get_conference {select conference_id, conference_type, imsld_item_id, moderator_id, manager_id from imsld_conference_services where service_id = cr_items.item_id and cr_items.latest_revision = :service_id}
      #Write imsld:conference label and content
      set imsld_conference [$doc createElement "imsld:conference"]
      $imsld_service appendChild $imsld_conference
      #Add conference-type
      $imsld_conference setAttribute conference-type $conference_type

      #Get title element
      db_1row get_title {select title from cr_revisions where revision_id = :conference_id}
      if {$title != ""} {
        set imsld_title [$doc createElement "imsld:title"]
        $imsld_conference appendChild $imsld_title
        $imsld_title appendChild [$doc createTextNode "$title"]
      }

      #Add participants if there are participants (get role identifier)
      db_multirow get_role get_role {select identifier from imsld_roles, acs_rels, cr_items cr1, cr_items cr2 where object_id_one = cr1.item_id and cr1.latest_revision = :conference_id and rel_type = 'imsld_conf_part_rel' and object_id_two = cr2.item_id and cr2.latest_revision = role_id} {
        #Create participant label
        set participant [$doc createElement "imsld:participant"]
        $imsld_conference appendChild $participant
        #Set role-ref attribute
        $participant setAttribute "role-ref" $identifier
      }

      #Write moderator info
      if {$moderator_id != ""} {
        #Get role-ref identifier
        db_1row get_role_ref {select identifier from imsld_roles, cr_items where :moderator_id = item_id and latest_revision = role_id}
        #Create conference-moderator label
        set moderator [$doc createElement "imsld:conference-moderator"]
        $imsld_conference appendChild $moderator
        #Set role-ref attribute
        $moderator setAttribute "role-ref" $identifier
      }

      #Write manager info
      if {$manager_id != ""} {
        #Get role-ref identifier
        db_1row get_role_ref {select identifier from imsld_roles, cr_items where :manager_id = item_id and latest_revision = role_id}
        #Create conference-moderator label
        set manager [$doc createElement "imsld:conference-manager"]
        $imsld_conference appendChild $manager
        #Set role-ref attribute
        $manager setAttribute "role-ref" $identifier
      }

    } elseif {$service_type == "monitor"} {
      #If the service is of type monitor, get monitor data and write it
      db_1row get_conference {select monitor_id, role_id, imsld_item_id from imsld_monitor_services where service_id = cr_items.item_id and cr_items.latest_revision = :service_id}
      #Write imsld:monitor label and content
      set imsld_monitor [$doc createElement "imsld:monitor"]
      $imsld_service appendChild $imsld_monitor

      #Write imsld:role-ref label and content
      set imsld_role_ref [$doc createElement "imsld:role-ref"]
      $imsld_monitor appendChild $imsld_role_ref
      db_1row get_role_ref {select identifier from imsld_roles where :role_id = cr_items.item_id and cr_items.latest_revision = role_id}
      #Add ref attribute
      $imsld_role_ref setAttribute ref $identifier

      #Write imsld:title label and content
      db_1row get_title {select title from cr_revisions where revision_id = :monitor_id}
      if {$title != ""} {
        set imsld_title [$doc createElement "imsld:title"]
        $imsld_monitor appendChild $imsld_title
        $imsld_title appendChild [$doc createTextNode "$title"]
      }

      if {$imsld_item_id != ""} {
        #Get monitor item data
        db_1row get_item {select identifier, identifierref, is_visible_p from imsld_items where :imsld_item_id = cr_items.item_id and cr_items.latest_revision = imsld_item_id}
        #Write imsld:item label and content
        set imsld_item [$doc createElement "imsld:item"]
        $imsld_monitor appendChild $imsld_item
        #Add attributes of imsld:item label
        if {$identifier != ""} {
          $imsld_item setAttribute identifier $identifier
        }
        #Check if the reference is of a xowiki page, if it is the case, fill identifierref with resource_(resource_number)
        if {[string first "item_" $identifier] == 0} {
          set identifierref "resource_[string range $identifier [expr [string first "_" $identifier]+1] end]"
        }
        $imsld_item setAttribute identifierref $identifierref
        if {$is_visible_p == "t"} {
          set is_visible "true"
        } else {
          set is_visible "false"
        }
        $imsld_item setAttribute isvisible $is_visible
        #Get title element
        db_1row get_title {select title from cr_revisions where item_id = :imsld_item_id}
        #If title exists
        if {$title != ""} {
          #Write imsld:title label and content
          set imsld_title [$doc createElement "imsld:title"]
          $imsld_item appendChild $imsld_title
          $imsld_title appendChild [$doc createTextNode "$title"]
        }
      }
    } elseif {$service_type == "send-mail"} {
      #If service is of type send-mail, write send-mail content
      db_1row get_send_mail_data {select mail_id, recipients, is_visible_p, parameters from imsld_send_mail_services, cr_items where service_id = cr_items.item_id and cr_items.latest_revision = :service_id}
      #Write imsld:send-mail label and content
      set imsld_send_mail [$doc createElement "imsld:send-mail"]
      $imsld_service appendChild $imsld_send_mail
      #Add select attribute
      if {$recipients != ""} {
        $imsld_service setAttribute select $recipients
      }
      #Add is-visible attribute
      if {$is_visible_p == "t"} {
        set is_visible "true"
      } else {
        set is_visible "false"
      }
      $imsld_send_mail setAttribute isvisible $is_visible

      #Write imsld:title label and content
      db_1row get_title {select title from cr_revisions where revision_id = :mail_id}
      if {$title != ""} {
        set imsld_title [$doc createElement "imsld:title"]
        $imsld_send_mail appendChild $imsld_title
        $imsld_title appendChild [$doc createTextNode "$title"]
      }


      #Add mail data if it exists
      db_foreach get_mail_data {select identifier, mail_data, email_property_id, username_property_id from imsld_roles roles, imsld_send_mail_data data, acs_rels, cr_items cr1, cr_items cr2, cr_items cr3 where object_id_one = cr1.item_id and cr1.latest_revision = :mail_id and rel_type = 'imsld_send_mail_serv_data_rel' and object_id_two = cr2.item_id and cr2.latest_revision = data_id and data.role_id = cr3.item_id and cr3.latest_revision = roles.role_id} {
        #Write imsld:email-data label and content
        set imsld_email_data [$doc createElement "imsld:email-data"]
        $imsld_send_mail appendChild $imsld_email_data

        #Write imsld:role-ref label and content
        set imsld_role_ref [$doc createElement "imsld:role-ref"]
        $imsld_email_data appendChild $imsld_role_ref
        #Add ref attribute
        $imsld_role_ref setAttribute ref $identifier

        #Write imsld:email-property-ref label and content
        set email_property_ref [$doc createElement "imsld:email-property-ref"]
        $imsld_email_data appendChild $email_property_ref
        
        #Add ref attribute
        $email_property_ref setAttribute ref $identifier
      }
    }
  }
}



