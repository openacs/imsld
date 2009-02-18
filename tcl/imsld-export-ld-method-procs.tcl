namespace eval imsld::export::ld::method {}

###############################################################################
# Call this function to create imsld:conditions label and write its content
###############################################################################
ad_proc -public imsld::export::ld::method::write_conditions {
  -doc:required
  -method:required
  -method_id:required
} {
  This proc is called to write all the information contained in 
   imsld:conditions label
} {
  set aux 0
  #Get conditions
  db_multirow get_conditions get_conditions {select condition_id, condition_xml from imsld_conditions where method_id = :method_id order by condition_id asc} {
    #Create conditions label in case it hasn't been created before
    if {$aux == 0} {
      set aux 1
      #Create conditions label
      set conditions [$doc createElement "imsld:conditions"]
      $method appendChild $conditions 
    }
 
    #Write condition
    #First, create the new document
    set condition [dom parse $condition_xml]
    #Get root element of the document
    set root [$condition documentElement]
    $conditions appendChild [$root firstChild] 
  }
}

###############################################################################
# Call this function to create imsld:play label and write its content
###############################################################################
ad_proc -public imsld::export::ld::method::write_play {
  -doc:required
  -method:required
  -method_id:required
} {
  This proc is called to write all the information contained in imsld:play label
} {
  set aux 1
  while {$aux > 0} {
    #Get play identifier and play_id (item_id)
    if {[db_0or1row get_play {select identifier, is_visible_p, item_id, complete_act_id from imsld_plays, cr_items where method_id = :method_id and latest_revision = play_id and sort_order = :aux}] == 1} {
      #First, I need to create the play label
      set imsld_play [$doc createElement "imsld:play"]
      $method appendChild $imsld_play

      #Write attribute identifier obtained from query get_play
      if {$identifier != ""} {
        $imsld_play setAttribute identifier $identifier
      }

      #Write imsld:title label and content
      set imsld_title [$doc createElement "imsld:title"]
      $imsld_play appendChild $imsld_title
      #Get title element
      db_1row get_title {select title from cr_revisions where item_id = :item_id}
      $imsld_title appendChild [$doc createTextNode "$title"]

      #Convert is_visible_p to string needed for attribute isvisible
      if {$is_visible_p == "t"} {
        set is_visible_p "true"
      } else {
        set is_visible_p "false"
      }
      #Write attribnute isvisible obtained from query get_play and formatted
      # in the lines just over this comment
      $imsld_play setAttribute isvisible $is_visible_p

      #Now, I have to create the acts
      imsld::export::ld::method::write_act -doc $doc -play $imsld_play -play_id $item_id

      #Write complete play if it exists
      if {$complete_act_id != ""} {
        set complete_play [$doc createElement "imsld:complete-play"]
        $imsld_play appendChild $complete_play
        db_1row get_complete_act {select when_last_act_completed_p, time_string, when_prop_val_is_set_xml from imsld_complete_acts where complete_act_id = cr_items.latest_revision and cr_items.item_id = :complete_act_id}
        if {$when_last_act_completed_p == "t"} {
          set when_last_act [$doc createElement "imsld:when-last-act-completed"]
          $complete_play appendChild $when_last_act
        }
        if {$time_string != ""} {
          set time_limit [$doc createElement "imsld:time-limit"]
          $complete_play appendChild $time_limit
          $time_limit appendChild [$doc createTextNode "$time_string"]
        }
        if {$when_prop_val_is_set_xml != ""} {
          #Write when-property-value-is-set
          #First, create the new document
          set when_prop_val [dom parse $when_prop_val_is_set_xml]
          #Get root element of the document
          set root [$when_prop_val documentElement]
          $complete_play appendChild $root
        }
      }
      set aux [expr $aux+1]
    } else {set aux 0}
  }
}

###############################################################################
# Call this function to create imsld:act label and write its content
###############################################################################
ad_proc -public imsld::export::ld::method::write_act {
  -doc:required
  -play:required
  -play_id:required
} {
  This proc is called to write all the information contained in imsld:act labels
} {
  #For each act recovered, create a new imsld:act label
  db_multirow get_act get_act {select identifier, act_id, complete_act_id, on_completion_id from imsld_acts where play_id = :play_id} {
    #First, I need to create the play label
    set imsld_act [$doc createElement "imsld:act"]
    $play appendChild $imsld_act
    #Write attribute identifier obtained from query get_act
    if {$identifier != ""} {
      $imsld_act setAttribute identifier $identifier
    }

    #Write imsld:title label and content
    set imsld_title [$doc createElement "imsld:title"]
    $imsld_act appendChild $imsld_title
    #Get title element
    db_1row get_title {select title from cr_revisions where revision_id = :act_id}
    $imsld_title appendChild [$doc createTextNode "$title"]

    db_multirow get_role_part_identifier get_role_part_identifier {select identifier, role_part_id, learning_activity_id, role_id, support_activity_id, activity_structure_id, environment_id from imsld_role_parts, cr_items where act_id = item_id and latest_revision = :act_id order by sort_order asc} {
      #Create label imsld:role-part
      set imsld_role_part [$doc createElement "imsld:role-part"]
      $imsld_act appendChild $imsld_role_part
      #Write attribute identifier obtained from query get_role_part
      if {$identifier != ""} {
        $imsld_role_part setAttribute identifier $identifier
      }

      #Write imsld:title label and content
      set imsld_title [$doc createElement "imsld:title"]
      $imsld_role_part appendChild $imsld_title
      #Get title element
      db_1row get_title {select title from cr_revisions where revision_id = :role_part_id}
      $imsld_title appendChild [$doc createTextNode "$title"]

      #Write imsld:role-ref label and content
      set imsld_role_ref [$doc createElement "imsld:role-ref"]
      $imsld_role_part appendChild $imsld_role_ref
      #Get role_ref element
      db_1row get_role {select identifier from imsld_roles, cr_revisions where role_id = revision_id and item_id = :role_id}
      $imsld_role_ref setAttribute ref $identifier
      #In case there is a learning activity associated, write it
      if {[db_0or1row get_learning_activity {select identifier from imsld_learning_activities, cr_revisions where activity_id = revision_id and item_id = :learning_activity_id}] == 1} {
        #Write imsld:learning-activity-ref label and content
        set imsld_ld_ref [$doc createElement "imsld:learning-activity-ref"]
        $imsld_role_part appendChild $imsld_ld_ref
        #Add identifier attibute
        $imsld_ld_ref setAttribute ref $identifier
      }
      #In case there is an activity structure associated, write it
      if {[db_0or1row get_activity_structure {select identifier from imsld_activity_structures, cr_revisions where structure_id = revision_id and item_id = :activity_structure_id}] == 1} {
        #Write imsld:activity-structure-ref label and content
        set imsld_as_ref [$doc createElement "imsld:activity-structure-ref"]
        $imsld_role_part appendChild $imsld_as_ref
        #Add ref attibute
        $imsld_as_ref setAttribute ref $identifier
      }
      #In case there is a support activity associated, write it
      if {[db_0or1row get_support_activity {select identifier from imsld_support_activities, cr_revisions where activity_id = revision_id and item_id = :support_activity_id}] == 1} {
        #Write imsld:activity-structure-ref label and content
        set imsld_sa_ref [$doc createElement "imsld:support-activity-ref"]
        $imsld_role_part appendChild $imsld_sa_ref
        #Add ref attibute
        $imsld_sa_ref setAttribute ref $identifier
      }
      ###################################
      # This is not implemented
      # (unit_of_learning)
      ###################################
      #In case there is an environment associated, write it
      if {[db_0or1row get_environment {select identifier from imsld_environments, cr_revisions where environment_id = revision_id and item_id = :environment_id}] == 1} {
        #Write imsld:activity-structure-ref label and content
        set imsld_environment_ref [$doc createElement "imsld:environment-ref"]
        $imsld_role_part appendChild $imsld_environment_ref
        #Add identifier attibute
        $imsld_environment_ref setAttribute ref $identifier
      }
    }

    #Create on-completion label in case it is necessary
    if {$on_completion_id != ""} {
      #Call proc to write imsld:on-completion label
      #Reuse proc for on-completion learning-activities
      imsld::export::ld::components::write_on_completion -doc $doc -learning_activity $imsld_act -on_completion_id $on_completion_id
    }
    #Create complete-activity label in case it is necessary
    if {$complete_act_id != ""} {
      #Call proc to write imsld:complete-activity label
      #Reuse proc for complete_act learning-activities
      imsld::export::ld::components::write_complete_activity -doc $doc -learning_activity $imsld_act -complete_act_id $complete_act_id
    }
  }
}
