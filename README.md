# mysql-ansible说明
  
**本项目源自开源项目mysqltools，其项目地址如下：**

[mysqltools](https://github.com/Neeky/mysqltools)

## 1. 准备工作

本工具是基于ansible开发的，因此需要一台中控机，这台机器最好能联网。

首先下载本项目，将下载好的zip包解压放置在/usr/local下。

```bash
cd /tmp
wget https://github.com/zhiyoucai/mysql-ansible/archive/master.zip

unzip master.zip

mv mysql-ansible-master /usr/local/mysql-ansible
```

接下来的工作是安装python，只需要在中控机上安装即可：

```bash
cd /usr/local/mysql-ansible/deploy/packages/python

sh install.sh
```

安装时需要的依赖我基本上都已经打包在项目中，大部分情况下是不需要联网的，但是难免挂一漏万，因此推荐中控机可以使用yum。

python安装完成后执行命令检查验证：

```bash
source /etc/profile

python3 --version
```

打印结果应该是3.6.2，这也是本项目依赖的python版本。

本项目是依赖ansible的，因此还需要手动安装ansible：

```bash
cd /usr/local/mysql-ansible/deploy/packages/ansible

sh install.sh
```

到这一步所有需要安装的工具都已经安装完毕，接下来需要新建ansible的hosts文件：

```bash
mkdir -p /etc/ansible

touch /etc/ansible/hosts
```

在这个文件中添加被控机器的信息：

```plain text
host_131 ansible_user=root ansible_host=172.16.192.131
host_132 ansible_user=root ansible_host=172.16.192.132
```

ansible要求中控机对被控机可以单向ssh信任，建立ssh信任的过程本文中不再赘述，仅作为注意事项。

这一切完成之后，我们可以执行这个命令测试一下连通性：

```bash
ansible -m ping host_131
```

结果返回SUCESS标记则表示一切配置成功，可以进行自动化部署了。

**本项目中基本的配置是config.yaml，在最高一级目录下存放，后文提及config.yaml的时候，就不会提及其存放位置了。**

配置文件中修改添加一些基本的信息，如下表：

|配置项|说明|
|---|---|
|mtls_base_dir|这是base目录，即项目的保存目录，建议不要更改|
|mtls_packages|这是安装包的保存路径，建议不要修改|
|mtls_client_base_dir|这是base目录，建议不要求改|

## 2. MySQL的部署

### 2.1 部署前的准备工作和注意事项

默认的配置文件中MySQL采用了5.7.29版本，而且采用rpm方式安装，在源项目mysqltools里，采用更广泛适配的binary包形式部署，鉴于我工作的环境都是CentOS，因此出于方便和让安装包尽量小的目的，我选择了RPM的管理方式。

由于RPM的安装包还是比较大，因此没有上传，需要的可以在官方网站上下载或者在国内镜像网站上下载。

本工具仅测试了MySQL5.7，对于其他大版本都没有测试过。

mysql-ansible项目支持如下几种结构的MySQL部署：

* 单实例MySQL；
* 双主MySQL结构；
* 一主N从MySQL结构；
* MySQL组复制结构。

这几种结构我们会在本文中一一阐明。

在所有的部署开始之前，我们需要修改config.yaml文件，修改MySQL的基本信息：

```yaml
# mysql安装包存放的位置，注意，一定要在最后加"/"
mysql_packages_dir: /usr/local/mysqltools/deploy/packages/mysql/
# mysql安装包，本工具只支持5.7版本，因此这里只能更换不同的版本，但不能更换包
mysql_version: 57
mysql_server_package: mysql-community-server-5.7.29-1.el7.x86_64.rpm
mysql_client_package: mysql-community-client-5.7.29-1.el7.x86_64.rpm
mysql_common_package: mysql-community-common-5.7.29-1.el7.x86_64.rpm
mysql_libs_package: mysql-community-libs-5.7.29-1.el7.x86_64.rpm
mysql_libs_compact_package: mysql-community-libs-compat-5.7.29-1.el7.x86_64.rpm
mysql_devel_package: mysql-community-devel-5.7.29-1.el7.x86_64.rpm
#linux 系统级别mysql用户相关信息
mysql_user: mysql
mysql_group: mysql
mysql_user_uid: 3306
mysql_user_gid: 3306
#mysql 数据目录
mysql_data_dir_base: /usr/local/mysql
mysql_port: 3306
mysql_root_password: i528jc4QqxGm0J88
# 用于复制的用户，默认创建，单实例安装的话，可以在安装完成之后手动删除该用户
mysql_repl_user: repl
mysql_repl_password: i528jc4QqxGm0J88
# MGR的monitor用户，非MGR安装可以在安装完成后手动删除
mysql_monitor_user: monitor
mysql_monitor_password: i528jc4QqxGm0J88
# XtraBackup需要的备份用户，如果不需要备份，可以在安装完成后手动删除
mysql_backup_user: backup
mysql_backup_password: i528jc4QqxGm0J88
#mysql 配置文件模版
mysql_binlog_format: row
mysql_innodb_log_files_in_group: 4
mysql_innodb_log_file_size: 512M
mysql_innodb_log_buffer_size: 64M
mysql_innodb_open_files: 65535
mysql_max_connections: 3000
mysql_thread_cache_size: 256
mysql_sync_binlog: 1
mysql_binlog_cache_size: 64K
mysql_innodb_online_alter_log_max_size: 128M
mysql_performance_schema: 'on'
use_write_set: 1
```

另外需要说明的是，MySQL的配置文件是预置在template/5.7/my.cnf中的，这个文件可以根据不同的需求进行定制，但是定制的时候，需要注意里面读取了config.yaml中的一些变量，这些变量需要格外注意不要搞错了。

### 2.2 单实例MySQL的部署

首先要修改hosts文件，添加一个标签：

```plain text
[single]
192.168.1.5
```

单实例部署的playbook是install_single_mysql.yaml。这个文件里虽然支持hosts属性的修改，但是鉴于是单实例，因此没有这个必要，直接写死成single了，在部署的时候也不需要修改，直接执行即可。

```bash
ansible-playbook install_single_mysql.yaml
```

如果要卸载，则需要修改一下uninstall.yaml文件，将hosts属性替换成single，执行命令：

```bash
ansible-playbook uninstall.yaml
```

部署完成之后，可以用`systemctl status mysqld`来观察服务状态。

### 2.3 一主N从的部署

首先要修改hosts文件，添加一个标签：

```plain text
[repl]
192.168.1.5
192.168.1.6
192.168.1.7
```

然后需要修改vars/master_slaves.yaml：

```yaml
#在创建一主多从环境时会用到的变量
## 是否开启基于writeset的并行复制机制
use_write_set: 1

## master 和 slave 对应的IP
master_ip: 192.168.1.5
slave_ips:
  - 192.168.1.6
  - 192.168.1.7
```

执行命令即可开始部署：

```bash
ansible-playbook install_master_slaves.yaml
```

要卸载如果要卸载，则需要修改一下uninstall.yaml文件，将hosts属性替换成repl，执行命令：

```bash
ansible-playbook uninstall.yaml
```

### 2.4 双主的部署

双主是一种特殊的主从结构，其特点是双向复制。

首先要修改hosts文件，添加一个标签：

```plain text
[repl]
192.168.1.5
192.168.1.6
```

然后需要修改vars/master_master.yaml：

```yaml
#在创建一主多从环境时会用到的变量
## 是否开启基于writeset的并行复制机制
use_write_set: 1

## master 和 slave 对应的IP
master_ip: 192.168.1.5
standby_ip: 192.168.1.6
```

执行命令即可开始部署：

```bash
ansible-playbook install_master_master.yaml
```

要卸载如果要卸载，则需要修改一下uninstall.yaml文件，将hosts属性替换成repl，执行命令：

```bash
ansible-playbook uninstall.yaml
```

### 2.5 组复制的部署

首先要修改hosts文件，添加一个标签：

```plain text
[mgr]
192.168.1.5
192.168.1.6
192.168.1.7
```

然后需要修改vars/master_master.yaml：

```yaml
mtls_with_mysql_group_replication: 1
mysql_binlog_format: row
mysql_mgr_port: 13306
mysql_mgr_first_primary: '192.168.1.5'
mysql_mgr_hosts:
    - '192.168.1.5'
    - '192.168.1.6'
    - '192.168.1.7'
```

执行命令即可开始部署：

```bash
# 建议首先给MGR的所有节点添加hosts信息
ansible-playbook prepare_hostname.yaml

ansible-playbook install_group_replication.yaml
```

要卸载如果要卸载，则需要修改一下uninstall.yaml文件，将hosts属性替换成mgr，执行命令：

```bash
ansible-playbook uninstall.yaml
```

组复制的特点是集群可以随需求进行扩容，本工具也支持组复制的扩容，首先要在hosts文件的mgr标签下添加新添加的节点（192.168.1.8），修改vars/group_replication.yaml，添加新的节点IP到mysql_mgr_hosts数组，然后开始执行下面的命令进行扩容：

```bash
# 准备域名
ansible-playbook prepare_hostname.yaml

# 在新的节点上安装mysql
ansible-playbook install_mysql.yaml -l 192.168.1.8

# 导数据，导出数据的时候，需要指定一个原先集群中节点的IP
ansible-playbook export_data.yaml -l 192.168.1.5

# 导入数据，这里参数比较复杂，需要首先指定一个src_host
ansible-playbook transfer_data.yaml --extra-vars "{'src_host':'192.168.1.5'}" -l 192.168.1.8
```

### 2.6 升级

本工具支持5.7版本内的小版本升级，而且这种小版本升级是不存在数据兼容性问题的，比较安全。

升级分为下面这些playbook：

* upgrade_single_mysql.yaml：升级单节点
* upgrade_master_slave_mysql.yaml：升级一主N从
* upgrade_master_master_mysql.yaml：升级双主
* upgrade_group_replication.yaml： 升级组复制

升级的时候，要首先修改config.yaml中的MySQL相关安装包，比如“mysql_client_package”的值就要修改成“mysql-community-client-5.7.30-1.el7.x86_64.rpm”，表示将这个包升级到5.7.30版本。

按照不同的结构去执行playbook即可完成升级操作。

## 3. 工具部署

MySQL有很多开源的周边工具，善于利用这些工具能够提升开发和运维的效率。

### 3.1 ProxySQL的部署

安装proxysql之前，需要首先安装python3到目标机器上。

修改/etc/ansible/hosts，添加proxysql标签：

```plain text
[proxysql]
192.168.1.2
```

在python的目录下，执行下面的命令安装python：

```bash
ansible-playbook install_python.yaml
```

这一步执行成功之后，可以在目标机器上用`python --version`检查是否安装了3.6.2版本。

执行安装命令进行安装：

```bash
ansible-playbook install_proxysql.yaml
```

到这一步就完成安装了，但是要注意的是，此时proxysql还是需要设置的，具体的配置方法参考proxysql的部署文档。

配置实际上也是支持的，只是现在还没有完全搞明白如何做，这部分内容作为未来的方向。

### 3.2 运维工具安装

现在支持的工具有：

* mydumer，标签是mydumper
* percona toolkits，标签是perconatoolkit
* sysbench，标签是sysbench
* xtrabackup，标签是xtrabackup

要部署哪个工具，就需要首先添加相关的标签到hosts文件中。安装过程调度相关目录下的playbook即可完成。
