delete from mysql_servers;
delete from mysql_group_replication_hostgroups;
delete from mysql_users;

-- 写入MySQL的服务节点信息，这些节点都是被代理的
insert into mysql_servers(hostgroup_id,hostname,port) 
values(10,'{{mysql_mgr_hosts[0]}}',3306),
      (10,'{{mysql_mgr_hosts[1]}}',3306),
      (10,'{{mysql_mgr_hosts[2]}}',3306);
-- 这一步一定要执行
load mysql servers to runtime;
save mysql servers to disk;

-- 刚才在数据库中新建的监控用户
set mysql-monitor_username='{{mysql_monitor_user}}';
set mysql-monitor_password='{{mysql_monitor_user}}';
load mysql variables to runtime;
save mysql variables to disk;
