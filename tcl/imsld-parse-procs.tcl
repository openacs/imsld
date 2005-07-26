# /packages/imsld/tcl/imsld-parse-procs.tcl

ad_library {
    Procedures in the imsld namespace for parsing xml files.
    
    @creation-date Jul 2005
    @author jopez@inv.it.uc3m.es
    @cvs-id $Id$
}

namespace eval imsld {}
namespace eval imsld::parse {}

ad_proc -public imsld::parse::find_manifest {
    -dir
    -file_name
} {
    Taken from the one with the same name in the LORS package.
    Find the manifest file (or other file) that contains
    the ims ld.
    if it finds it, then it returns the file location. Otherwise it 
    returns 0

    @param tmp_dir Temporary directory where the course is located
    @param file Manifest file
} {
    if { [file exist $dir/$file_name] } {
        return "$dir/$file_name"
    } else {
        return 0
    }
}

ad_proc -public imsld::parse::is_imsld {
    -tree:required
} {
    Checks it the given tree has the IMS LD extension and if the IMS LD comes in the organization.

    Returns a list (pair of values): 1 + OK if succeeded, 0 + error message otherwise.

    @param tree XML tree to analyze.
} {
    
    # Check the manifest attribute
    set man_attribute [$tree hasAttribute xmlns:imsld]

    # Check manifest organizations
    set organizations [$tree child all organizations]

    if { [llength $organizations] == 1 } {
        
        set imsld [$organizations child all imsld:learning-design]
        
        if { [llength $imsld] > 1 } {
            # There are more than one imsld in the organization, not supported
            return [list 0 "<#_ The manifest has more than one imsld:learning design. Right now this is not supported, sorry. #>"]
        }

    } else {
        # There are more than one organizations, or there is none. None of those cases supported, aborting
        return [list 0 "<#_ The manifest doesn't contain any organizations or there are more than one. None of those cases are supported in this version, sorry. #>"]
    }

    # After validating the cases above, we can say that this seems a well formed IMS LD
    return [list 1 "<#_ OK #>"]
}

ad_proc -public imsld::parse::expand_file {
    -upload_file:required
    -tmpfile:required
    {-dest_dir_base "imsld"}
} {
    Taken from the one with the same name in the LORS package.
    Extracts the contents of the file and puts them in the folder
    indicated by dest_dir. If empty, it will generate a tmp_dir for the extraction.

    Returns the name of the directory where the files where extracted.

    @param upload_file Path of the file to be extracted
    @param tmpfile Temporary file name
    @option dest_dir_base Destination directory where the files will be extracted
} {

    # Generate a random directory name
    if { [catch {set tmp_dir [file join [file dirname $tmpfile] [ns_mktemp "$dest_dir_base-XXXXXX"]]} errmsg] } {
        form set_error upload_file_form upload_file "<#_ There was an error generating the tmp_dir to unzip the file. #> $errmsg"
        return -code error "IMSLD::imsld::parse::expand_file: Error generating tmp directory: $errmsg"
    }

    # Create a temporary directory
    if { [catch {file mkdir $tmp_dir} errmsg] } {
        form set_error upload_file_form upload_file "<#_ There was an error creating the tmp_dir to unzip the file. #> $errmsg"
        return -code error "IMSLD::imsld::parse::expand_file: Error creating tmp directory: $errmsg"
    }

    set upload_file [string trim [string tolower $upload_file]]

    if {[regexp {(.tar.gz|.tgz)$} $upload_file]} { 
        set type tgz 
    } elseif {[regexp {.tar.z$} $upload_file]} { 
        set type tgZ 
    } elseif {[regexp {.tar$} $upload_file]} { 
        set type tar 
    } elseif {[regexp {(.tar.bz2|.tbz2)$} $upload_file]} { 
        set type tbz2 
    } elseif {[regexp {.zip$} $upload_file]} { 
        set type zip 
    } else { 
        set type "<#_ Uknown type #>" 
    } 
    
    switch $type {
        tar {
            set error_p [catch {exec tar --directory $tmp_dir -xvf $tmpfile} errmsg]
        }
        tgZ {
            set error_p [catch {exec tar --directory $tmp_dir -xZvf $tmpfile} errmsg]
        }
        tgz {
            set error_p [catch {exec tar --directory $tmp_dir -xzvf $tmpfile} errmsg]
        }
        tbz2 {
            set error_p [catch {exec tar --directory $tmp_dir -xjvf $tmpfile} errmsg]
        }
        zip {
            set error_p [catch {exec unzip -d $tmp_dir $tmpfile} errmsg]
            
            ## According to man unzip:
            # unzip exit status:
            #
            # 0      normal; no errors or warnings
            # detected.
            
            # 1 one or more warning errors were encountered, but process-
            #   ing  completed  successfully  anyway.  This includes zip-
            #   files where one or more files was skipped due  to  unsup-
            #   ported  compression  method or encryption with an unknown
            #   password.
            
            # Therefor it if it is 1, then it concluded successfully
            # but with warnings, so we switch it back to 0
            
            if { $error_p == 1 } {
                set error_p 0
            }
        }
        default {
            set error_p 1
            set errmsg "<#_ Could not determine whit what program uncompress the file $upload_file has. Aborting #>"
        }
    }
    
    if { $error_p } {
        imsld::parse::remove_dir -dir $tmp_dir
        ns_log Notice "IMSLD::imsld::parse::expand_file: extract type $type failed $errmsg"
        return -code error "IMSLD::imsld::parse::expand_file: extract type $type failed $errmsg"
    }
    return $tmp_dir
}

ad_proc -public imsld::parse::get_title {
    -tree
} {
    Gets the title of the given doc. If the title is not found (because it's optional), the identifier (which is mandatory) is returned.

    @param doc XML document to analyze.
} {
    set title_list [$tree child all title]
    if { [llength $title_list] } {
        return [imsld::parse::get_element -tree $title_list]]
    } else {
        return [imsld::parse::get_attribute -tree $tree -attr_name identifier]
    }
}

ad_proc -public imsld::parse::get_element {
    -tree 
    {-attr_name ""}
} {
    Taken from the one with the same name in the LORS package.
    Datatype Element extractor
    
    @param tree Node
    @param att Attribute
    
} {
    if { ![empty_string_p $attr_name] } {
        return [list "{[$tree text]} {[imsld::parse::get_attribute -tree $tree -attr_name $attr_name]}"]
    } else {
        return [list [$tree text]]
    }
}

ad_proc -public imsld::parse::get_attribute {
    -tree
    -attr_name
} {
    Taken from the one with the same name in the LORS package.
    Gets attributes for an specific element. Returns the attribute value if fond, emtpy string otherwise

    @param tree Document
    @param attr_name Attribute we want to fetch
} {
    if { [$tree hasAttribute $attr_name] == 1 } {
        $tree getAttribute $attr_name
    } else {
        return ""
    }
}

ad_proc -public imsld::parse::validate_multiplicity {
    -tree
    -multiplicity
    -element_name
    -equal:boolean
    -greather_than:boolean
    -lower_than:boolean
} {
    Validates the multiplicity of a given tree. It throws an error if the multiplicity is greather or equal than, lowher or equal than or not equal to the number especified in the multiplicity param.

    Only one vaidation can be done at the same time, and by default, equal is pefrormed.

    @param tree Document
    @param multiplicity Number of times the element can be repeated
    @param element_name Name of the element we are validating (in order to display a possible error message)
    @option equal If passed, the number of roots of the tree must be equal to multiplicity
    @option greather_than If passed, the number of roots of the tree must be greather or equal than multiplicity
    @option lower_than If passed, the number of roots of the tree must be lower or equal than multiplicity
} {
    if { [expr $equal_p + $greather_than_p + $lower_than_p] > 1 } {
        return -code error "IMSLD:imsld::parse::validate_multiplicity: <#_ More than one validation tried at the same time#>"
    }
    if { ![expr $equal_p + $greather_than_p + $lower_than_p] } {
        set equal_p 1
    }

    if { $equal_p } {
        if { [llength $tree] != $multiplicity } {
            ad_return_error "<#_ Error parsing file #>" "<#_ There must be exactly $multiplicity $element_name and there are [llength $tree]. This is not supported, sorry. #>"
            ad_script_abort
        }
    } elseif { $greather_than_p } {
        if { [llength $tree] < $multiplicity } {
            ad_return_error "<#_ Error parsing file #>" "<#_ There can't be less than $multiplicity $element_name and there are [llength $tree]. This is not supported, sorry. #>"
            ad_script_abort
        } 
    } else {
        if { [llength $tree] > $multiplicity } {
            ad_return_error "<#_ Error parsing file #>" "<#_ There can't greather than $multiplicity $element_name and there are [llength $tree]. This is not supported, sorry. #>"
            ad_script_abort
        } 
    }
}

ad_proc -public imsld::parse::remove_dir {
    -dir:required
} {
    Deletes the given directory.
    For instance, the tmp_dir used to extract the files and parse them.

    Returns 1 when succeded, 0 otherwise

    @param dir directory to be deleted.
} {
    if { [file exist $dir] } {
        if { [catch {exec rm -rf $dir} errmsg] } {
            return -code error "IMSLD:imsld::parse::remove_dir: <#_ There was an error trying to delete the dir $dir. #> $errmsg"
        }
    }

    return 1
}

ad_proc -public imsld::parse::tcl_boolean {
    -bool:required
} {
    Convets a boolean string to its corresponding boolean value 0 or 1. 

    @param bool The boolean value to convert
} {
    set result ""
    set value [string tolower $bool]

    switch $bool {
        0 -
        f -
        n -
        no -
        false {
            set result 0
        }
        1 -
        t -
        y -
        yes -
        true {
            set result 1
        }
        default {
            set result 0
            ns_log error "Invalid option in imsld::parse::tcl_boolean - $bool"
        }
    }
    return $result 
}

ad_proc -public imsld::parse::parse_and_create_imsld { 
    -xmlfile:required
    -imsld_id:optional
} {
    Parse a XML IMS LD file. 

    Returns the new imsld_id created if there was no errors. Otherwise it returns 0.
    
    @param xmlfile The file to parse. This file must be compliant with the IMS LD spec
    @option imsld_id The imsld_id of the new ims-ld
} {

	# Parser
	# XML => DOM document
	dom parse [::tDOM::xmlReadFile $xmlfile] document

	# DOM document => DOM root
	$document documentElement root
    set organizations [$manifest child all organizations]

    # IMS-LD
    set imsld [$organizations child all imsld:learning-design]
    set imsld_title [imsld::parse::get_title -tree $imsld]
    set imsld_level [imsld::parse::get_attribute -tree $imsld -attr_name level]
    set imsld_level [expr { [empty_string_p $imsld_level] ? "null" : [string tolower $imsld_level] }]
    set imsld_version [imsld::parse::get_attribute -tree $imsld -attr_name version]
    set imsld_sequence_used [imsld::parse::get_attribute -tree $imsld -attr_name sequence-used]
    set imsld_sequence_p [expr { [empty_string_p $imsld_sequence_used] ? 0 : [imsld::parse::tcl_boolean -bool $imsld_sequence_used] }]

    # IMS-LD: Learning Objectives (which is an imsld_item that can have a text resource associated.)
    set learning_objectives [$imsld child all imsld:learning-objectives]
    imsld::parse::validate_multiplicity -tree $learning_objectives -multiplicity 1 -element_name learning-objectives -lower_than
    

    # Components
    set components [$imsld child all imsld:components]
    imsld::parse::validate_multiplicity -tree $components -multiplicity 1 -element_name components -equal

    # Components: Roles
    set roles [$components child all imsld:roles]
    set learners [$roles child all imsld:learner]
    set staff [$roles child all imsld:staff]

    # Componetns: Activities
    set activities [$components child all imsld:activities]
    if { [llength $activities] } {
        set learning_activities [$activities child all imsld:learning-activity]
        set support_activities [$activities child all imsld:support-activity]
        set activity_structures [$activities child all imsld:activity-structure]
    }

    # Method
    set methods [$imsld child all imsld:method]
    imsld::parse::validate_multiplicity -tree $methods -multiplicity 1 -element_name methods -equal
    
    # Method: Play
    set plays [$methods child all imsld:play]
    imsld::parse::validate_multiplicity -tree $plays -multiplicity 1 -element_name plays -equal

    # Method: Acts
    set acts [$plays child all imsld:act]
    imsld::parse::validate_multiplicity -tree $acts -multiplicity 0 -element_name acts -greather_than



    
	set questestinteropNodes [$root selectNodes {/questestinterop}]
	foreach questestinterop $questestinteropNodes {
		# Looks for assessments
		set assessmentNodes [$questestinterop selectNodes {assessment}]
		if { [llength $assessmentNodes] > 0 } {
			# There are assessments
			foreach assessment $assessmentNodes {
				set as_assessments__title [$assessment getAttribute {title} {Assessment}]
				#get assessment's children: section, (qticomment, duration, qtimetadata, objectives, assessmentcontrol, 
				#rubric, presentation_material, outcomes_processing, assessproc_extension, assessfeedback,
				#selection_ordering, reference, sectionref)
				set nodesList [$assessment childNodes]
				set as_assessments__definition ""
				set as_assessments__instructions ""
				set as_assessments__duration ""
				#for each assessment's child
				foreach node $nodesList {
					set nodeName [$node nodeName]
					#as_assessmentsx.description = <qticomment> or <objectives>
					if {$nodeName == "qticomment"} {
						set definitionNodes [$assessment selectNodes {qticomment}]
						if {[llength $definitionNodes] != 0} {
							set definition [lindex $definitionNodes 0]
							set as_assessments__definition [as::qti::mattext_gethtml $definition]
						}
					} elseif {$nodeName == "objectives"} {
						set definitionNodes [$assessment selectNodes {objectives/material/mattext}]
						if {[llength $definitionNodes] != 0} {
							set definition [lindex $definitionNodes 0]
							set as_assessments__definition [as::qti::mattext_gethtml $definition]
						}
					#as_assessments.instructions = <rubric>
					} elseif {$nodeName == "rubric"} {
						set instructionNodes [$assessment selectNodes {rubric/material/mattext}]
						if {[llength $instructionNodes] != 0} {
							set instruction [lindex $instructionNodes 0]
							set as_assessments__instructions [as::qti::mattext_gethtml $instruction]
						}
					#as_assessments.time_for_response = <duration>	
					} elseif {$nodeName == "duration"} {
					        set durationNodes [$assessment selectNodes {duration/text()}]
						if {[llength $durationNodes] != 0} {
							set duration [lindex $durationNodes 0]
							set as_assessments__duration [$duration nodeValue]
						}
					} 
				}
				set qtimetadataNodes [$assessment selectNodes {qtimetadata}]
				set as_assessments__run_mode ""
				set as_assessments__anonymous_p f
				set as_assessments__secure_access_p f
				set as_assessments__reuse_responses_p f
				set as_assessments__show_item_name_p f
				set as_assessments__consent_page ""
				set as_assessments__return_url ""
				set as_assessments__start_time ""
				set as_assessments__end_time ""
				set as_assessments__number_tries ""
				set as_assessments__wait_between_tries ""
				set as_assessments__ip_mask ""
				set as_assessments__show_feedback "none"
				set as_assessments__section_navigation "default path"
								
				set itemfeedbacknodes [$root selectNodes {/questestinterop/assessment/section/item/itemfeedback}]
				if { [llength $itemfeedbacknodes] >0} {
				    set as_assessments__show_feedback "all"
				}
				set resprocessNodes [$root selectNodes {/questestinterop/assessment/section/item/resprocessing}]
				set as_assessments__survey_p {f}				
				if { [llength $resprocessNodes] == 0 } {				     
				     set as_assessments__survey_p {t}
				     #if it's a survey don't show feedback
				     set as_assessments__show_feedback "none"				     
				}			
				
				if {[llength $qtimetadataNodes] > 0} {
				    #nodes qtimetadatafield
				    set qtimetadatafieldNodes [$qtimetadataNodes selectNodes {qtimetadatafield}]
				    foreach qtimetadatafieldnode $qtimetadatafieldNodes {
				         set label [$qtimetadatafieldnode selectNodes {fieldlabel/text()}]
					 set label [$label nodeValue]
				         set value [$qtimetadatafieldnode selectNodes {fieldentry/text()}]
					 set value [$value nodeValue]
					 					 
					 switch -exact -- $label {
					     run_mode {
					         set as_assessments__run_mode $value					 
					     }
					     anonymous_p {
					         set as_assessments__anonymous_p $value					 
					     }
					     secure_access_p {
					         set as_assessments__secure_access_p $value				 
					     }
					     reuse_responses_p {
					         set as_assessments__reuse_responses_p $value				 
					     }
					     show_item_name_p {
					         set as_assessments__show_item_name_p $value				 
					     }
					     consent_page {
					         set as_assessments__consent_page $value				 
					     }
					     start_time {
					         set as_assessments__start_time $value					 
					     }
					     end_time {
					         set as_assessments__end_time $value					 
					     }
					     number_tries {
					         set as_assessments__number_tries $value				 
					     }
					     wait_between_tries {
					         set as_assessments__wait_between_tries $value				 
					     }
					     ip_mask {
					        set as_assessments__ip_mask $value
					     }
					     show_feedback {
					        set as_assessments__show_feedback $value
					     }
					     section_navigation {
					        set as_assessments__section_navigation $value
					     }
					 }
					 
				    }				    
				}				
					
				# Insert assessment in the CR (and as_assessments table) getting the revision_id (assessment_id)
				set as_assessments__assessment_id [as::assessment::new \
				                                   -title $as_assessments__title \
								   -description $as_assessments__definition \
								   -instructions $as_assessments__instructions \
								   -run_mode $as_assessments__run_mode \
								   -anonymous_p $as_assessments__anonymous_p \
								   -secure_access_p $as_assessments__secure_access_p \
								   -reuse_responses_p $as_assessments__reuse_responses_p \
								   -show_item_name_p $as_assessments__show_item_name_p \
								   -consent_page $as_assessments__consent_page \
								   -return_url $as_assessments__return_url \
								   -start_time $as_assessments__start_time \
								   -end_time $as_assessments__end_time \
								   -number_tries $as_assessments__number_tries \
								   -wait_between_tries $as_assessments__wait_between_tries \
								   -time_for_response $as_assessments__duration \
								   -ip_mask $as_assessments__ip_mask \
								   -show_feedback $as_assessments__show_feedback \
								   -section_navigation $as_assessments__section_navigation \
								   -survey_p $as_assessments__survey_p ]			
				
				# Section
				set sectionNodes [$assessment selectNodes {section}]
				set as_assessment_section_map__sort_order 0
				foreach section $sectionNodes {					
					set as_sections__title [$section getAttribute {title} {Section}]
					#get section's children (qticomment, duration, qtimetadata, objectives, sectioncontrol, 
					#sectionprecondition, sectionpostcondition, rubric, presentation_material, outcomes_processing,
					#sectionproc_extension, sectionfeedback, selection_ordering, reference, itemref, item, sectionref,
					#section)
					set nodesList [$section childNodes]
					set as_sections__definition ""
					set as_sections__instructions ""
					set as_sections__duration ""
					set as_sections__sectionfeedback ""
					#for each section's child
					foreach node $nodesList {
						set nodeName [$node nodeName]
						#as_sectionsx.description = <qticomment> or <objectives>
						if {$nodeName == "qticomment"} {
							set definitionNodes [$section selectNodes {qticomment}]
							if {[llength $definitionNodes] != 0} {
								set definition [lindex $definitionNodes 0]
								set as_sections__definition [as::qti::mattext_gethtml $definition]
							}
						} elseif {$nodeName == "objectives"} {
						    set definitionNodes [$section selectNodes {objectives/material/mattext}]
						    if {[llength $definitionNodes] != 0} {
							set definition [lindex $definitionNodes 0]
							set as_sections__definition [as::qti::mattext_gethtml $definition]
						    }		
						#as_sections.max_time_to_complete = <duration>    				    
					        } elseif {$nodeName == "duration"} {
						    set section_durationNodes [$section selectNodes {duration/text()}]
						    if {[llength $section_durationNodes] != 0} {
							set section_duration [lindex $section_durationNodes 0]
							set as_sections__duration [$section_duration nodeValue]
						    }				
						#as_sections.instructions = <rubric>    		    
					        } elseif {$nodeName == "rubric"} {
						    set section_instructionNodes [$section selectNodes {rubric/material/mattext}]
						    if {[llength $section_instructionNodes] != 0} {
							set section_instruction [lindex $section_instructionNodes 0]
							set as_sections__instructions [as::qti::mattext_gethtml $section_instruction]
						    }				
						#as_sections.feedback_text = <sectionfeedback>    		        
					        } elseif {$nodeName == "sectionfeedback"} {
						    set sectionfeedbackNodes [$section selectNodes {sectionfeedback/material/mattext}]
						    if {[llength $sectionfeedbackNodes] != 0} {
							set sectionfeedback [lindex $sectionfeedbackNodes 0]
							set as_sections__sectionfeedback [as::qti::mattext_gethtml $sectionfeedback]
						    }				
					        } 							
					}
					
					set qtimetadataNodes [$section selectNodes {qtimetadata}]
					set as_sections__num_items ""
					set as_sections__points ""
					set asdt__display_type none
					set asdt__s_num_items ""
					set asdt__adp_chunk ""
				        set asdt__branched_p f
					set asdt__back_button_p t
					set asdt__submit_answer_p f
					set asdt__sort_order_type order_of_entry
					
					if {[llength $qtimetadataNodes] > 0} {
				    	    #nodes qtimetadatafield
				            set qtimetadatafieldNodes [$qtimetadataNodes selectNodes {qtimetadatafield}]
				            foreach qtimetadatafieldnode $qtimetadatafieldNodes {
				                set label [$qtimetadatafieldnode selectNodes {fieldlabel/text()}]
					  	set label [$label nodeValue]
				         	set value [$qtimetadatafieldnode selectNodes {fieldentry/text()}]
					 	set value [$value nodeValue]
					 						 
					 	switch -exact -- $label {
					     	    num_items {
					                set as_sections__num_items $value			
						    }
					     	    points {
					                set as_sections__points $value
						    }
					            display_type {
					                set asdt__display_type $value
						    }
					     	    s_num_items {
					                set asdt__s_num_items $value 
					     	    }
						    adp_chunk {
					                set asdt__adp_chunk $value 
					     	    }	
						    branched_p {
						        set asdt__branched_p $value				
						    }
						    back_button_p {
						        set asdt__back_button_p $value
						    }
						    submit_answer_p {
						        set asdt__submit_answer_p $value
						    }
						    sort_order_type {
						        set asdt__sort_order_type $value
						    }				     
						 }   
					     }					 
				        }	
					
					#section display type
					set display_type_id [as::section_display::new \
			                                   -title $asdt__display_type \
							   -num_items $asdt__s_num_items \
							   -adp_chunk $asdt__adp_chunk \
							   -branched_p $asdt__branched_p \
							   -back_button_p $asdt__back_button_p \
							   -submit_answer_p $asdt__submit_answer_p \
							   -sort_order_type $asdt__sort_order_type]
					# Insert section in the CR (and in the as_sections table) getting the revision_id (section_id)
					set section_id [as::section::new \
					                             -title $as_sections__title \
								     -description $as_sections__definition \
								     -instructions $as_sections__instructions \
								     -feedback_text $as_sections__sectionfeedback \
								     -max_time_to_complete $as_sections__duration \
								     -num_items $as_sections__num_items \
								     -points $as_sections__points \
								     -display_type_id $display_type_id]
									
					# Relation between as_sections and as_assessments
					db_dml as_assessment_section_map_insert {}
					incr as_assessment_section_map__sort_order
					set as_item_section_map__sort_order 0
					# Process the items
					set as_items [as::qti::parse_item $section [file dirname $xmlfile]]
					# Relation between as_items and as_sections
					foreach as_item_list $as_items {
					    array set as_item $as_item_list
					    set as_item_id $as_item(as_item_id)
					    set as_item__duration $as_item(duration)
					    set as_item__points $as_item(points)
					    db_dml as_item_section_map_insert {}
					    incr as_item_section_map__sort_order
					}
					
					#get points from a section
					db_0or1row get_section_points {}
					#update as_assessment_section_map with section points
					db_dml update_as_assessment_section_map {}
				}
			}
		} else {
			# Just items (no assessments)
			as::qti::parse_item $questestinterop [file dirname $xmlfile]]
		}
	}
	return $as_assessments__assessment_id
}




