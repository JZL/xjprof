# Run LIKE
# watch -n 30 send_signal_jl.sh
# ps within watch does weird things when columns limited
export COLUMNS=500
kill -SIGUSR1 `ps aux|grep \[t\]est.jl|grep -v bash|awk '{print $2}'`
