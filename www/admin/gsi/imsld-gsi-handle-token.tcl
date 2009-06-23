 ad_page_contract {
    @author lfuente@it.uc3m.es
    @creation-date mar 2009
} {
    gservice_id
    run_id
    plugin_URI
    user_id
    token
} 

#set user_id [ad_conn user_id]

#the token received is a single use one. Let's upgrade it
package require TclCurl
#the url where tokens are upgraded to session tokens
set url "https://www.google.com/accounts/AuthSubSessionToken"
set curlHandle [curl::init]

#if we have a token, we can upgrade it
if { ![string eq $token ""] } {

    #set the headers an configure the handlers with them
   set httpHeaders ""
   lappend httpHeaders "Content-Type: application/x-www-form-urlencoded"
   lappend httpHeaders "Authorization: AuthSub token=\"$token\""
   lappend httpHeaders "Connection: keep-alive"

   $curlHandle configure -url $url 
   $curlHandle configure -httpheader $httpHeaders 
   $curlHandle configure -headervar http_code -bodyvar html_code

   $curlHandle perform
} 
ns_log Notice "$html_code"
set token [string trim [lindex [split $html_code "="] 1]]
ns_log Notice "$token"

#token upgraded, let's store it
imsld::gsi::map_user -user_id $user_id -run_id $run_id -external_credentials $token -plugin_URI $plugin_URI

ad_returnredirect [export_vars -base "imsld-gsi-service-configure" {gservice_id run_id}]
