#!/bin/bash -x
set -euo pipefail

PGB_DIR="/home/pgbouncer"
INI="${PGB_DIR}/pgbouncer.ini"
USERLIST="${PGB_DIR}/userlist.txt"

PGB_ADMIN_USERS="setudbuser"
PGB_ADMIN_PASSWORDS="bmL829U6PvHmff72KGIg6BZDIi4183Ac"

# if [ -z ${PGB_ADMIN_USERS+x} ]; then
#   PGB_ADMIN_USERS="setudbuser"
#   PGB_ADMIN_PASSWORDS="bmL829U6PvHmff72KGIg6BZDIi4183Ac"
# fi

# Auto-generate conf if it doesn't exist
# if [ ! -f ${INI} ]; then
#   if [[ -z "${PGB_DATABASES:-}" ]]; then
#     echo "Error: no databases specified in \$PGB_DATABASES"
#     exit 1
#   fi

cat <<- END > $INI
[databases]
    setudb = host=organisatie-dev-eks-qa-db-2.cgaimxq41enr.ap-south-1.rds.amazonaws.com port=5432 user=setudbuser password=bmL829U6PvHmff72KGIg6BZDIi4183Ac dbname=setudb topology_query='select endpoint from rds_tools.show_topology(\'pgbouncer\')'
[pgbouncer]
    listen_port = 6432
    listen_addr = *
    auth_type = md5
    server_tls_sslmode = require
    default_pool_size = 20
    log_connections = 1
    log_disconnections = 1
    log_pooler_errors = 1
    routing_rules_py_module_file = /home/pgbouncer/routing_rules.py
    log_stats = 1
    auth_file = /home/pgbouncer/userlist.txt
    logfile = /home/pgbouncer/pgbouncer.log
    pidfile = /home/pgbouncer/pgbouncer.pid
    admin_users = admin
    pool_mode = transaction
    max_client_conn = 10000
    polling_frequency = 100
    server_failed_delay = 5
    recreate_disconnected_pools = 1
END
  cat $INI
fi

# Auto-generate conf if it doesn't exist
if [ ! -f ${USERLIST} ]; then
  # convert comma-separated string variables to arrays.
  IFS=',' read -ra admin_array <<< "$PGB_ADMIN_USERS"
  IFS=',' read -ra password_array <<< "$PGB_ADMIN_PASSWORDS"

  # check every admin account has a corresponding password, and vice versa
  if (( ${#admin_array[@]} != ${#password_array[@]} )); then
      exit 1
  fi

  # Zip admin arrays together and write them to userlist.
  for (( i=0; i < ${#admin_array[*]}; ++i )); do
      echo "\"${admin_array[$i]}\" \"${password_array[$i]}\"" >> $USERLIST
  done
fi

chmod 0600 $INI
chmod 0600 $USERLIST
#/pub_metrics.sh &
#/adaptivepgbouncer.sh &
pgbouncer $INI ${VERBOSE:-}
