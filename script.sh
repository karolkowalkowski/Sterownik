#temp u dzieci
t1=10
#temp na zewnątrz
t2=20
#temp piwnica
t3=30
#temp pok. północny
t4=40
#temp salon
t5=50
gpio mode 25 out
gpio mode 28 out
gpio mode 29 out
gpio write 25 1
gpio write 28 1
gpio write 29 1

#stan 0/1/2/3/4/5/6
# 0 - nic nie wlaczac
# 1 - podtrzymanie
# 2 - maly piec wlaczony
# 3 - duzy piec wlaczony
# 4 - oba piece wlaczone
# 5 - stan używany tylko na początku
# 6	- podlewanie

sleep 120

#stan początkowy
s="5" 

while true; do
   # do stuff
echo
echo $(date)
echo
#piec maly
#if [test $(gpio read 25)=1]
#then
#	echo "piec maly wylaczony" 
#	p1="O"
#else
#	echo "piec maly wlaczony"
#	p1="1"
#fi

t1=$(head /mnt/1wire/28.98B8A7271901/temperature)
echo "temperatura u chłopakow t1 ="$t1

t2=$(head /mnt/1wire/28.AA69E52F1901/temperature)
echo "temperatura na zewnatrz t2 = "$t2


t4=$(head /mnt/1wire/28.E711C22F1901/temperature)
echo "temperatura pokoj pln t4 = "$t4

t5=$(head /mnt/1wire/28.5E3DE42F1901/temperature)
echo "temperatura salon t5 = "$t5

#piec duzy
#if [test $(gpio read 28)=1]
#then
#	echo "piec duzy wylaczony" 
#	p2="O"
#else
#	echo "piec duzy wlaczony"
#	p2="1"
#fi

#p1="$p1"&p2="$p2"&

url="http://kkowalkowski.nstrefa.pl/arduino/index.php?t1="$t1"&t2="$t2"&t3="$t3"&t4="$t4"&t5="$t5"&s="$s"&z2=d3u129d83u12d3981u129d83u12d38u"
echo $url
content=$(curl -s -X GET "$url")
if [ $content = "arduino403" ]
then
	echo "piece oba włączone"
	s="4"
elif [ $content = "arduino303" ]
then
	echo "piec duży włączony"
	s="3"
elif [ $content = "arduino203" ]
then
	echo "piec maly wlaczony"
	s="2"
elif [ $content = "arduino103" ]
then
	echo "podtrzymanie"
	s="1"
elif [ $content = "arduino003" ]
then
	echo "wszystko wyłączone"
	s="0"
elif [ $content = "arduino603" ]
then
	echo "podlewanie"
	s="6"
else
	echo "nie odebrane"
	s="0"
fi

#gpio write...
if [ $s = "1" ]
then
	echo "stan podtrzymania wlaczony"
	#tymczasowo
	gpio write 25 1
	gpio write 28 1
	gpio write 29 1
elif [ $s = "2" ]
then 
	echo "stan maly piec wlaczony"
	gpio write 25 0
	gpio write 28 1
	gpio write 29 1
elif [ $s = "3" ]
then 
	echo "stan duzy piec wlaczony"
	gpio write 25 1
	gpio write 28 0
	gpio write 29 1
elif [ $s = "4" ]
then 
	echo "stan oba piece wlaczony"
	gpio write 25 0
	gpio write 28 0
	gpio write 29 1
elif [ $s = "6" ]
then 
	echo "stan podlewanie wlaczony"
	gpio write 25 1
	gpio write 28 1
	gpio write 29 0
	sleep $[10 * 60] #10min podlewania
	echo "koniec podlewania"
	gpio write 25 1 #wylaczamy wszystko
	gpio write 28 1
	gpio write 29 1
elif [ $s = "0" ]
then 
	echo "stan wylaczenie systemu wlaczony"
	gpio write 25 1
	gpio write 28 1
	gpio write 29 1
else
	echo "else"
	gpio write 25 1
	gpio write 28 1
	gpio write 29 1
fi
sleep 1200
done
