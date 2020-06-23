{% if master_ip in ansible_all_ipv4_addresses %}
SET SQL_LOG_BIN=0;
    create user {{mysql_repl_user}}@'%' identified by '{{mysql_repl_password}}';
    grant replication slave,replication client on *.* to {{mysql_repl_user}}@'%';

    flush privileges;
change master to
    master_host='{{standby_ip}}',
    master_port={{mysql_port}},
    master_user='{{mysql_repl_user}}',
    master_password='{{mysql_repl_password}}',
    master_auto_position=1;
start slave;
SET SQL_LOG_BIN=1;
{% else %}
SET SQL_LOG_BIN=0;
create user {{mysql_repl_user}}@'%' identified by '{{mysql_repl_password}}';
    grant replication slave,replication client on *.* to {{mysql_repl_user}}@'%';

    flush privileges;

change master to
    master_host='{{master_ip}}',
    master_port={{mysql_port}},
    master_user='{{mysql_repl_user}}',
    master_password='{{mysql_repl_password}}',
    master_auto_position=1;

start slave;
SET SQL_LOG_BIN=1;
{% endif %}
