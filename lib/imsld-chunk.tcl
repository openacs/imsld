# imsld/lib/imsld-chunk.tcl

ad_page_contract {
    @author jopez@inv.it.uc3m.es
    @creation-date Sept 2005
    @cvs-id $Id$
}

imsld::next_activity -imsld_item_id $imsld_item_id -return_url [ad_conn url] imsld_multirow

set elements [list prereqs \
                  [list label "Prerequisites" \
                       display_template "@imsld_multirow.prerequisites;noquote@"]]
lappend elements objectives \
    [list label "Learning Objectives" \
         display_template "@imsld_multirow.objectives;noquote@"]
lappend elements environments \
    [list label "Environments" \
         display_template "@imsld_multirow.environments;noquote@"]
lappend elements activity_title \
    [list label "Activity" \
         display_template "@imsld_multirow.activities_titles;noquote@"]
lappend elements activity_files \
    [list label "" \
         display_template "@imsld_multirow.activities_files;noquote@"]
lappend elements feedbacks \
    [list label "Feedback" \
         display_template "@imsld_multirow.feedbacks;noquote@"]
lappend elements status \
    [list label "Status" \
         display_template "@imsld_multirow.status;noquote@"]

template::list::create \
    -name imsld_uol \
    -multirow imsld_multirow \
    -key imsld_id \
    -pass_properties { return_url mode base_url bottom_line max_grade_label max_weight_label solution_label submitted_label grade_of_label} \
    -no_data "no data" \
    -elements $elements

