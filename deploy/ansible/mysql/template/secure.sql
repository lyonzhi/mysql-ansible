set sql_log_bin=0;
    alter user root@'localhost' identified by '{{ mysql_root_password }}' ;
    create user root@'127.0.0.1' identified by '{{ mysql_root_password }}';
    grant all on *.* to root@'127.0.0.1' with grant option;

    create user {{mysql_monitor_user}}@'127.0.0.1' identified by '{{ mysql_monitor_password }}' ;
    grant select on sys.* to {{mysql_monitor_user}}@'127.0.0.1';
    
    create user {{ mysql_backup_user }}@'localhost' identified by '{{ mysql_backup_password }}';
    grant lock tables, process, reload, replication client on *.* to '{{ mysql_backup_user }}'@'localhost';

    install plugin group_replication soname 'group_replication.so';
set sql_log_bin=1;

