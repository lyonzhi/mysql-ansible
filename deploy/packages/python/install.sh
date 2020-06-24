#!/bin/bash
#注意要用root用户运行这个脚本

base_dir=/usr/local/mysql-ansible/deploy/packages/python

#1、安装python相关的依赖
rpm -Uvh $base_dir/dependency/*.rpm

#2、安装python
pythondir=`dirname $0`
cd $pythondir

tar -xvf python-3.6.2.tar.xz -C /tmp/
cd /tmp/Python-3.6.2/
./configure --prefix=/usr/local/python-3.6.2/
make -j $(nproc)
make install
cd /usr/local/
ln -s /usr/local/python-3.6.2  python


echo 'export PATH=/usr/local/python/bin/:$PATH' >> /etc/profile

export PATH=/usr/local/python/bin/:$PATH

pip3 install $base_dir/dependency/six-1.11.0-py2.py3-none-any.whl
pip3 install $base_dir/dependency/protobuf-3.6.0-cp36-cp36m-manylinux1_x86_64.whl
pip3 install $base_dir/dependency/mysql_connector_python-8.0.12-cp36-cp36m-manylinux1_x86_64.whl

pip3 install $base_dir/mysqltools-python/mysqltools-python-2.18.12.01.tar.gz


if [ -f /tmp/python-3.6.2.tar.xz ];then
   rm -rf /tmp/python-3.6.2.tar.xz
fi


