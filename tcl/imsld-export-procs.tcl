namespace eval imsld::export {}

###############################################################################
# Call this function to export an UoL
###############################################################################
ad_proc -public imsld::export::uol {
  -run_imsld_id:required
  -resource_list:required
} {
  This proc is called when an UoL is needed to be exported
} {
  #First, create the new document
  set doc [dom createDocument manifest]
  #Get root element of the document
  set root [$doc documentElement]

  #Get object references to imsld components with run_imsld_id
  db_1row get_imsld_data {select * from imsld_imslds where imsld_id = :run_imsld_id}
  #Get manifest_id from imsld_cp_organizations table
  db_1row get_manifest_id {select manifest_id from imsld_cp_organizations where organization_id = cr_items.latest_revision and cr_items.item_id = :organization_id}
  #Get manifest_id2
  db_1row get_manifest_id2 {select object_id from acs_objects where context_id = :manifest_id}
  set manifest_id2 $object_id

  #Call proc to fill manifest label attributes
  imsld::export::write_manifest -manifest $root -manifest_id $manifest_id2 -imsld_id $run_imsld_id

  #Call proc to fill metadata part of imsmanifest.xml
  imsld::export::write_metadata -doc $doc -manifest $root -manifest_id $manifest_id

  #Call proc to fill organizations part of imsmanifest.xml
  imsld::export::write_organizations -doc $doc -manifest $root -manifest_id $manifest_id -imsld_id $run_imsld_id -learning_objective_id $learning_objective_id -prerequisite_id $prerequisite_id

  #Call proc to fill resources part of imsmanifest.xml
  imsld::export::write_resources -doc $doc -manifest $root -manifest_id $manifest_id -resource_list $resource_list

  #Return the document as xml
  $root asXML
  return "[$doc asXML]"
}

###############################################################################
# Call this function to create fill the manifest attributes
###############################################################################
ad_proc -public imsld::export::write_manifest {
  -manifest:required
  -manifest_id:required
  -imsld_id:required
} {
  This proc is called to write the manifest attributes of the document
} {
  #Get UoL identifier
  db_1row get_manifest_identifier {select identifier from imsld_cp_manifests where manifest_id = :manifest_id}
  #Get manifest level
  db_1row manifest_level {select level from imsld_imslds where imsld_id = :imsld_id}
  if {$level == "a"} {
    set level A
  } elseif {$level == "b"} {
    set level B
  } elseif {$level == "c"} {
    set level C
  }
  #Write namespaces
  $manifest setAttribute xmlns "http://www.imsglobal.org/xsd/imscp_v1p1"
  $manifest setAttribute xmlns:imsld "http://www.imsglobal.org/xsd/imsld_v1p0"
  $manifest setAttribute xmlns:xsi "http://www.w3.org/2001/XMLSchema-instance"
  $manifest setAttribute xsi:schemaLocation "http://www.imsglobal.org/xsd/imscp_v1p1 http://www.imsglobal.org/xsd/imscp_v1p1p3.xsd http://www.imsglobal.org/xsd/imscp_v1p0 http://www.imsglobal.org/xsd/IMS_LD_Level_${level}.xsd"
  if {$identifier != ""} {
    $manifest setAttribute identifier $identifier
  }
}

###############################################################################
# Call this function to create metadata label and content
###############################################################################
ad_proc -public imsld::export::write_metadata {
  -doc:required
  -manifest:required
  -manifest_id:required
} {
  This proc is called to write metadata label and content
} {
  ##############################################################
  # This is not implemented due to it is not supported in Grail
  ##############################################################
  #Not stored in grail
  #set metadata [$doc createElement metadata]
  #$metadata appendChild [$doc createTextNode "Estoy en funcion write_metadata"]
  #$manifest appendChild $metadata
}

###############################################################################
# Call this function to create organizations label and content
###############################################################################
ad_proc -public imsld::export::write_organizations {
  -doc:required
  -manifest:required
  -manifest_id:required
  -imsld_id:required
  -learning_objective_id:required
  -prerequisite_id:required
} {
  This proc is called to write organizations label and content
} {

  set organizations [$doc createElement organizations]
  $manifest appendChild $organizations

  imsld::export::write_learning_design -doc $doc -organizations $organizations -organizations_id $manifest_id -imsld_id $imsld_id -learning_objective_id $learning_objective_id -prerequisite_id $prerequisite_id

}

###############################################################################
# Call this function to create resources label and content
###############################################################################
ad_proc -public imsld::export::write_resources {
  -doc:required
  -manifest:required
  -manifest_id:required
  -resource_list:required
} {
  This proc is called to write resources label and content
} {
  #First, create resources label
  set resources [$doc createElement resources]
  $manifest appendChild $resources
  #Get resources and write them into the manifest document
  db_multirow get_resources get_resources {select * from imsld_cp_resources where manifest_id = :manifest_id} {
      #First, I need to create a resource label
      set resource [$doc createElement "resource"]
      $resources appendChild $resource
      #Write attribute identifier, type and href obtained from query get_resources
      if {$identifier != ""} {
        $resource setAttribute identifier $identifier
      }
      $resource setAttribute type $type
      if {$href != ""} { 
        $resource setAttribute href $href
      }
      #Check resource_list to look for additional resource files to the ones referenced in the database
      if {[lindex $resource_list 0] == "NONE" || $href == ""} {
        set resource_files_list [list]
      } else {
        set position [lsearch $resource_list $href]
        if {$position != -1} {
          set resource_files_list [lindex $resource_list [expr $position+1]]
        } else {
          set resource_files_list [list]
        }
      }
      #Call proc to fill files information for the resource
      imsld::export::write_files -doc $doc -resource $resource -resource_id $resource_id -resource_files_list $resource_files_list
  }
}

###############################################################################
# Call this function to create files label and content
###############################################################################
ad_proc -public imsld::export::write_files {
  -doc:required
  -resource:required
  -resource_id:required
  -resource_files_list:required
} {
  This proc is called to write files label and content
} {
    #Get file_ids of the resource given
    db_multirow get_file_ids get_file_ids {select object_id_two from acs_rels where object_id_one = cr_items.item_id and cr_items.latest_revision = :resource_id} {
      #Get content type to proceed depending on type (imsld_cp_file, ::xowiki::Page or ::xowiki::File)
      db_1row get_content_type {select content_type, name from cr_items where item_id = :object_id_two}
      
      if {$content_type == "imsld_cp_file"} {
        #Get href for each file returned in the get_files_ids query
        if {[db_0or1row get_file_href {select href from imsld_cp_files where imsld_file_id = cr_items.latest_revision and cr_items.item_id = :object_id_two}] == 1} {
          #Create file label
          set one_file [$doc createElement "file"]
          $resource appendChild $one_file
          #Add href attribute
          $one_file setAttribute href ${href}
        }
      } else {
        if {[string first "link" $name] != 0} {
          #Create file label
          set one_file [$doc createElement "file"]
          $resource appendChild $one_file

          set pos [string first "/" $name]
	  if {$pos == -1} {
            regsub -all {:} $name {_} name
            if {[string last "." $name] < [string length $name]-5} {
	      set name ${name}.html
            }
	  }
	  set href [string range $name [expr $pos+1] end]
      
          #Add href attribute
          $one_file setAttribute href ${href}
	}
      }
    }
    #Write file resources from resource_file_list
    if {[llength $resource_files_list] > 0} {
      foreach res_file $resource_files_list {
        set one_file [$doc createElement "file"]
        $resource appendChild $one_file
        #Add href attribute
        $one_file setAttribute href ${res_file}
      }
    }
}

###############################################################################
# Call this function to create learning-design label and content
###############################################################################
ad_proc -public imsld::export::write_learning_design {
  -doc:required
  -organizations:required
  -organizations_id:required
  -imsld_id:required
  -learning_objective_id:required
  -prerequisite_id:required
} {
  This proc is called to write learning-design label and content
} {

  set learning_design [$doc createElement "learning-design"]
  $organizations appendChild $learning_design

  #Get learning-design identifier and add it as attribute
  db_1row get_ld_identifier {select identifier, level, sequence_used_p from imsld_imslds where imsld_id = :imsld_id}

  #Format level to write the attribute properly
  if {$level == "a"} {
    set level A
  } elseif {$level == "b"} {
    set level B
  } elseif {$level == "c"} {
    set level C
  } else {
    #Return error
    return 0
  }

  #Write namespaces
  $learning_design setAttribute xmlns "http://www.imsglobal.org/xsd/imsld_v1p0"
  $learning_design setAttribute xmlns:xsi "http://www.w3.org/2001/XMLSchema-instance"
  $learning_design setAttribute xsi:schemaLocation "http://www.imsglobal.org/xsd/imsld_v1p0 http://www.imsglobal.org/learningdesign/ldv1p0/IMS_LD_Level_${level}.xsd"
  if {$identifier != ""} {
    $learning_design setAttribute identifier $identifier
  }
  $learning_design setAttribute level $level
  #Format sequence_used to write the attribute properly
  if {$sequence_used_p == "" || $sequence_used_p == "f"} {
    set sequence_used false
  } else {
    set sequence_used true
  }
  $learning_design setAttribute sequence_used $sequence_used

  #Write imsld:title label and content
  set imsld_title [$doc createElement "imsld:title"]
  $learning_design appendChild $imsld_title
  #Get title element
  db_1row get_title {select title from cr_revisions where revision_id = :imsld_id}
  $imsld_title appendChild [$doc createTextNode "$title"]

  #Call proc that fills learning-objectives
  imsld::export::ld::write_learning_objectives -doc $doc -learning_design $learning_design -learning_objective_id $learning_objective_id

  #Call proc that fills prerequisites
  imsld::export::ld::write_prerequisites -doc $doc -learning_design $learning_design -prerequisite_id $prerequisite_id

  #Call proc that fills components
  imsld::export::ld::write_components -doc $doc -learning_design $learning_design -imsld_id $imsld_id

  #Call proc that fills method
  imsld::export::ld::write_method -doc $doc -learning_design $learning_design -imsld_id $imsld_id
}

