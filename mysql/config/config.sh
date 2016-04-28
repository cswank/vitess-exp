#!/bin/bash


until mysql -h mysql-master -uroot -e "select * from riak_index" dev_marketing_email
do
  echo "waiting for mysql"
  sleep 1
done

until mysql -h mysql-slave-1 -uroot -e "select * from riak_index" dev_marketing_email
do
  echo "waiting for mysql slave 1"
  sleep 1
done

until mysql -h mysql-slave-2 -uroot -e "select * from riak_index" dev_marketing_email
do
  echo "waiting for mysql slave 2"
  sleep 1
done

mysql -h mysql-master -uroot -e "GRANT REPLICATION SLAVE ON *.* TO repl@'%' IDENTIFIED BY 'slavepass'"

mysql -h mysql-master -uroot -e "SHOW MASTER STATUS\G"

FILE=$(mysql -h mysql-master -uroot dev_marketing_email -e 'SHOW MASTER STATUS\G' | grep File | cut -d ':' -f2 | xargs)
POS=$(mysql -h mysql-master -uroot dev_marketing_email -e 'SHOW MASTER STATUS\G' | grep Position | cut -d ':' -f2 | xargs)

mysql -h mysql-slave-1 -uroot -e "change master to master_host='mysql-master',master_user='repl',master_password='slavepass',master_log_file='$FILE',master_log_pos=$POS;" -vvv
mysql -h mysql-slave-2 -uroot -e "change master to master_host='mysql-master',master_user='repl',master_password='slavepass',master_log_file='$FILE',master_log_pos=$POS;" -vvv

mysql -h mysql-slave-1 -uroot -e "START SLAVE" -vvv
mysql -h mysql-slave-2 -uroot -e "START SLAVE" -vvv
