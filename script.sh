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

#zmienna do podtrzymania grzania pieca o 2stopnie jak już sie włączy...
piecWlaczony=0

#stan piecow:
p1=0 #piec maly
p2=0 #piec duzy

#stan 0/1/2/3/4/5/6
# 0 - nic nie wlaczac
# 1 - podtrzymanie
# 2 - maly piec wlaczony
# 3 - duzy piec wlaczony
# 4 - oba piece wlaczone
# 5 - stan używany tylko na początku
# 6	- podlewanie

#stan początkowy
s="5" 

while true; do
   # do stuff
echo
echo $(date)
echo

t1=$(head /mnt/1wire/28.98B8A7271901/temperature)
echo "temperatura u chłopakow t1 ="$t1

t2=$(head /mnt/1wire/28.AA69E52F1901/temperature)
echo "temperatura na zewnatrz t2 = "$t2


t4=$(head /mnt/1wire/28.E711C22F1901/temperature)
echo "temperatura pokoj pln t4 = "$t4

t5=$(head /mnt/1wire/28.5E3DE42F1901/temperature)
echo "temperatura salon t5 = "$t5

#stan wyjscia na piec maly
stanPiecaMalego=$(gpio read 25) 
if [ $stanPiecaMalego = "1" ]
then
	echo "piec maly wylaczony" 
	p1="O"
else
	echo "piec maly wlaczony"
	p1="1"
fi

#stan wyjscia na piec duzy
stanPiecaDuzego=$(gpio read 28) 
if [ $stanPiecaDuzego = "1" ]
then
	echo "piec duzy wylaczony" 
	p2=0
else
	echo "piec duzy wlaczony"
	p2=1
fi

sleep 120 #czekamy aż wstanie modem po wlaczeniu

url="http://kkowalkowski.nstrefa.pl/arduino/index.php?t1="$t1"&t2="$t2"&t3="$t3"&t4="$t4"&t5="$t5"&s="$s"&p1="$p1"&p2="$p2"&z2=d3u129d83u12d3981u129d83u12d38u"
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

pokojFloat=$t4
pokojInteger=${pokojFloat%.*}

naDworzeFloat=$t2
naDworzeInteger=${naDworzeFloat%.*}

#gpio write...
if [ $s = "1" ]
then
	echo "stan podtrzymania wlaczony"
	if [ $naDworzeInteger -lt 1 ] ## [[ "$supportLeft" -lt 1 ] || [ "$yearCompare" -gt 0 ]] -> mniejsze od 1 większe od 0
	then
		echo "jest zimniej niz 0"
		if [ $pokojInteger -lt 4 ]
		then
			piecWlaczony=1
			gpio write 25 1
			gpio write 28 0 #wlaczamy piec duzy
			gpio write 29 1
			echo "wlaczamy piec bo jest zimniej w domu niz 4 stopnie"
		elif [ $pokojInteger -gt 5 ]
		then
			echo "wylaczamy piec bo jest cieplej w domu niz 6 stopni"
			piecWlaczony=0
			gpio write 25 1
			gpio write 28 1 #wylaczamy piec duzy
			gpio write 29 1
		else
			if [ $piecWlaczony = "0" ]
			then
				echo "jest okolo 5 stopni, ale nie bylo zimniej"
				gpio write 25 1
				gpio write 28 1 #wylaczamy piec duzy
				gpio write 29 1
			else
				echo "piec chodzi, bo bylo zimniej niz 4 stponie - dlatego czekamy jeszcze do podgrzania"
				gpio write 25 1
				gpio write 28 0 #podtrzymujemy wlaczenie pieca duzego
				gpio write 29 1
			fi
			
		fi
	else
		piecWlaczony=0
		gpio write 25 1
		gpio write 28 1
		gpio write 29 1
		echo "jest cieplej niz 0"
		#wylaczamy wiec wszystko
	fi
	
elif [ $s = "2" ]
then 
	echo "stan maly piec wlaczony"
	piecWlaczony=0
	gpio write 25 0
	gpio write 28 1
	gpio write 29 1
elif [ $s = "3" ]
then 
	echo "stan duzy piec wlaczony"
	piecWlaczony=0
	gpio write 25 1
	gpio write 28 0
	gpio write 29 1
elif [ $s = "4" ]
then 
	piecWlaczony=0
	echo "stan oba piece wlaczony"
	gpio write 25 0
	gpio write 28 0
	gpio write 29 1
elif [ $s = "6" ]
then 
	piecWlaczony=0
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
	piecWlaczony=0
	echo "stan wylaczenie systemu wlaczony"
	gpio write 25 1
	gpio write 28 1
	gpio write 29 1
else
	piecWlaczony=0
	echo "else"
	gpio write 25 1
	gpio write 28 1
	gpio write 29 1
fi
#sleep 10
#60 sekund razy 60 min = 1h
#sleep $[15]
sleep 1080
done
