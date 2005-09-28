ad_page_contract {
}

set page_title index
set context {}

db_foreach imsld_in_class {
    select all imslds in the class
} {
#     set next_activity [imsld::get_next_activity]
#     display ismld_name
#     display copmleted activities
#     display next activity with "finished" link and with link to the activity: if it is an activity structure?
}


