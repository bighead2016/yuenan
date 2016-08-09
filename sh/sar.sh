sar -b 10 1140 >> /tmp/sar-b.txt &
sar -r 10 1140 >> /tmp/sar-r.txt &
sar -n DEV 10 1440 >> /tmp/sar-n.txt &
sar -P ALL 10 1440 >> /tmp/sar-p.txt &
sar -W 10 1440 >> /tmp/sar-w.txt &