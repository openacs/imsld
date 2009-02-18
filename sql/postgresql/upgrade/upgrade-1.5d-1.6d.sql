-- 
-- 
-- 
-- @author Derick Leony (derick@inv.it.uc3m.es)
-- @creation-date 2008-12-16
-- @arch-tag: /bin/bash: uuidgen: command not found
-- @cvs-id $Id$
--

alter table imsld_imslds add column resource_handler varchar(100);
comment on column imsld_imslds.resource_handler is '
Indicates which package is used to handle the resource objects for the UoL (file-storage or xowiki).';

update imsld_imslds set resource_handler = 'file-storage';

alter table imsld_imslds alter column resource_handler set not null;

