
set sql_log_bin=0;
create user {{mysql_repl_user}}@'%' identified by '{{mysql_repl_password}}';
grant replication slave,replication client on *.* to {{mysql_repl_user}}@'%';
set sql_log_bin=1;

change master to 
    master_user='{{mysql_repl_user}}',
    master_password='{{mysql_repl_password}}'
    for channel 'group_replication_recovery';

{% if mysql_mgr_first_primary in ansible_all_ipv4_addresses %}
    set global group_replication_bootstrap_group=on;
    start group_replication;
    set global group_replication_bootstrap_group=off;
{% else %}
    select sleep(10);
    start group_replication;
{% endif %}
