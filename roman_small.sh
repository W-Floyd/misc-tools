#!/bin/sh
b=0
l=0
for u in $(sed 's/./& /g' <<<$1|rev);do
case $u in
i)n=1
;;
v)n=5
;;
x)n=10
;;
l)n=50
;;
c)n=100
;;
d)n=500
;;
m)n=1000
esac
[ $n -gt $l ]&&l=$n
[ $b -lt $n ]&&s=+||{
[ $b = $n ]&&{
[ $n -lt $l ]&&s=-||s=+
}||s=-
}
b=$n
e=$e$s$n
done
echo $((e))
exit
