ZPOOLS=`zpool list -H| nawk '{print $1}'`

echo zpool,components
for z in $ZPOOLS; do
	zpool iostat -v $z 1 1 | nawk -v zpool=$z '/capacity|--|pool|$zpool/{next}{components=components":"$1}END{ printf "%s,%s\n", zpool,components}'
done	

