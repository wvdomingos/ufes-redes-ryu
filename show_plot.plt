set term png small size 800,600
set output "iperf-graph.png"

set yrange[0:1250]
set ytics(0,250,500,750,1000,1250)
set xrange[0:16]
set xtics(0,2,4,6,8,10,12,14,16)
set ylabel "Kbytes"
set xlabel "Tempo"

plot "new_resulth1" title "porta 5001" with linespoints, \
     "new_resulth2" title "porta 5002" with linespoints