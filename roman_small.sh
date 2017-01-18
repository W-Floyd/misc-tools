#!/bin/sh
b=0
e=0
l=0
for u in $(sed 's/./& /g' <<< $1 | rev)
do
case "$u" in
i)
n=1
;;
v)
n=5
;;
x)
n=10
;;
l)
n=50
;;
c)
n=100
;;
d)
n=500
;;
m)
n=1000
;;
esac
if [ $n -gt $l ]
then
l=$n
fi
if [ $b -lt $n ]
then
s=+
elif [ $b = $n ]
then
if [ $n -lt $l ]
then
s=-
else
s=+
fi
else
s=-
fi
b=$n
e=$e$s$n
done
echo $e | bc
exit
