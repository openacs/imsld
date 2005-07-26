# /packages/imsld/www/admin/imsld-new-2.tcl

ad_page_contract {

    Pre parse the IMS LD ZIP file and requests confirmation from the user.
    
    @author jopez@inv.it.uc3m.es
    @creation-date jul 2005
} {
    upload_file:trim
    upload_file.tmpfile:tmpfile
    return_url
} -properties {
    upload_file
    context:onevalue
}

set package_id [ad_conn package_id]
permission::require_permission -object_id $package_id -privilege create

set page_title "<#_ Confirm: New IMS-LD #>"
set context [list [list "<#_ New IMS-LD #>" "new-imsld"] [list "<#_ Confirm: New IMS-LD #>"]]

set user_id [ad_conn user_id]
set imsld_id [db_nextval acs_object_id_seq]

# expand file
set tmp_dir [imsld::parse::expand_file -upload_file $upload_file -tmpfile ${upload_file.tmpfile} -dest_dir_base imsld-${imsld_id}]

# search for manifest file
set manifest [imsld::parse::find_manifest -dir $tmp_dir -file_name "imsmanifest.xml"]

# see if the file actually is where it suppose to be. Othewise abort
if {$manifest == 0} {
    imsld::parse::remove_dir -dir $tmp_dir
    ad_return_error "<#_ No imsmanifest.xml found #>" "<#_ No imsmanifest.xml was found in the compressed file. Aborting. #>"
    ad_script_abort
}

# open the imsmanifest.xml file
dom parse [::tDOM::xmlReadFile $manifest] doc
set manifest [$doc documentElement]

# Pair of values, success_p + explanation
set is_imsld_list [imsld::parse::is_imsld -tree $manifest]

if { [lindex $is_imsld_list 0] } {

    multirow create imsld_info element_name info

    template::list::create \
        -name imsld_info \
        -multirow imsld_info \
        -no_data "<#_ No information found in the manifest file #>" \
        -elements {
            element_name {
                label ""
                html {valign top style "background-color: #e0e0e0; font-weight: bold;"}
            }
            info {
                label ""
                html {valign top style "background-color: #f0f0f0; font-weight: bold;"}
            }
            
        }

    # Get the info from the manifest
    set organizations [$manifest child all organizations]
    multirow append imsld_info "<#_ Number of Organizations: #>" [llength $organizations]
    set imsld [$organizations child all imsld:learning-design]
    multirow append imsld_info "<#_ Number of IMD LDs #>" [llength $imsld]
    set imsld_title [imsld::parse::get_title -tree $imsld]
    set imsld_level [imsld::parse::get_attribute -tree $imsld -attr_name level]
    set imsld_level [expr { [empty_string_p $imsld_level] ? "<#_ Not defined #>" : $imsld_level }]
    multirow append imsld_info "<#_ IMD LD Title #>" [llength $imsld]
    multirow append imsld_info "<#_ IMD LD Level #>" "$imsld_level"
    
    # Components
    set components [$imsld child all imsld:components]
    imsld::parse::validate_multiplicity -tree $components -multiplicity 1 -element_name components -equal

    set roles [$components child all imsld:roles]
    set learners [llength [$roles child all imsld:learner]]
    set staff [llength [$roles child all imsld:staff]]
    multirow append imsld_info "<#_ Total Roles #>" [expr $learners + $staff]
    multirow append imsld_info "<#_ Learners Roles #>" $learners
    multirow append imsld_info "<#_ Staff Roels #>" $staff

    set activities [$components child all imsld:activities]
    if { [llength $activities] } {
        set learning_activities [llength [$activities child all imsld:learning-activity]]
        set support_activities [llength [$activities child all imsld:support-activity]]
        set activity_structures [llength [$activities child all imsld:activity-structure]]
        multirow append imsld_info "<#_ Total Activities #>" [expr $learning_activities + $support_activities + $activity_structures]
        multirow append imsld_info "<#_ Learning Activities #>" $learning_activities
        multirow append imsld_info "<#_ Support Activities #>" $support_activities
        multirow append imsld_info "<#_ Activity Structures #>" $activity_structures
    } 

    # Methods
    set methods [$imsld child all imsld:method]
    imsld::parse::validate_multiplicity -tree $methods -multiplicity 1 -element_name methods -equal
    
    set plays [$methods child all imsld:play]
    imsld::parse::validate_multiplicity -tree $plays -multiplicity 1 -element_name plays -equal

    set acts [$plays child all imsld:act]
    imsld::parse::validate_multiplicity -tree $acts -multiplicity 0 -element_name acts -greather_than
    multirow append imsld_info "<#_ Acts #>" [llength $acts]
    
} else {
    # Not valid (or supported?) IMS LD
    ad_return_error "<#_ No IMS LD #>" "Couldn't determine if this is a well formed IMS-LD: [lindex $is_imsld_list 1]"
    ad_script_abort
}

ad_form -name imsld_upload -cancel_url $return_url -action imsld-new-3 -html { enctype multipart/form-data } -form {
    imsld_id:key
    
    {tmp_dir:text {widget hidden} {value $tmp_dir}}
}
