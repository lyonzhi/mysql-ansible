delete from mysql_group_replication_hostgroups;
insert into mysql_group_replication_hostgroups(writer_hostgroup,backup_writer_hostgroup,reader_hostgroup,offline_hostgroup,active,max_writers,writer_is_also_reader,max_transactions_behind) 
values(10,20,30,40,1,1,0,0);
load mysql servers to runtime;
save mysql servers to disk;
