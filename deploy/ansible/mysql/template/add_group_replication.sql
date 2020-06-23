-- reset master;
change master to 
    master_user='{{mysql_repl_user}}',
    master_password='{{mysql_repl_password}}'
    for channel 'group_replication_recovery';
start group_replication;
