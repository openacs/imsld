# 

ad_page_contract {
    
    Plain XoWiki layout
    
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2008-09-16
    @arch-tag: 76c59bb9-3e48-4db5-8b82-acb7de600dda
    @cvs-id $Id$
} {
    item_id:integer,notnull
} -properties {
} -validate {
} -errors {
}

set url [ns_urldecode [imsld::xowiki::page_url -item_id $item_id]]

