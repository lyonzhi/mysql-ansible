
set sql_log_bin=0;


{% if mysql_mgr_first_primary in ansible_all_ipv4_addresses %}
    set global group_replication_bootstrap_group=on;
    start group_replication;
    set global group_replication_bootstrap_group=off;
{% else %}
    select sleep(5);
    start group_replication;
{% endif %}
