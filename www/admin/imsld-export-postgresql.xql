<?xml version="1.0"?>
<queryset>
  <fullquery name="get_files_1">
    <querytext>
      select imsld_file_id, path_to_file from imsld_cp_files where imsld_file_id > :this_imsld and :next_imsld > imsld_file_id and file_name != 'imsmanifest.xml'
    </querytext>
  </fullquery>
  <fullquery name="get_files_2">
    <querytext>
      select imsld_file_id, path_to_file from imsld_cp_files where imsld_file_id > :this_imsld and file_name != 'imsmanifest.xml'
    </querytext>
  </fullquery>
</queryset>
