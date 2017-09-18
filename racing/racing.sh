#!/bin/bash
declare -c w=$(tput cols)
declare -c h=$(tput lines)
declare -g lvl=5
declare -g spd=1
declare -g dif=7
declare -g score=0
declare -g key
declare -g screen
declare -g s

declare -g KEY_LEFT="a"
declare -g KEY_RIGHT="d"

gen_road() {
	st=$1
	local l="."
	for ((i=1; $i < $st; i=i+1)); do
		l=$l"."
	done
	l=$l"||"
	for ((i=1; $i < 15; i=i+1)); do
		c=$RANDOM; let "c %= $dif"
		if [ $c -eq 2 ]; then
			c="0"
		else
			c="."
		fi
		l=$l$c
	done
	l=$l"||"
	for ((i=1; $i < $w-$st-18; i=i+1)); do
		l=$l"."
	done
	screen="$l
$screen"
}

gen_empty_road() {
	for ((n=1; $n < $h-1; n=n+1)); do
		local l="."
		for ((i=1; $i < $s; i=i+1)); do
			l=$l"."
		done
		l=$l"||"
		for ((i=1; $i < 15; i=i+1)); do
			l=$l"."
		done
		l=$l"||"
		for ((i=1; $i < $w-$s-18; i=i+1)); do
			l=$l"."
		done
		screen="$l
$screen"
	done
}

init() {
	clear
	stty -echo
	#hide cursor
	echo -e "\033[?25l"
	
	if [ $1 -ge 1 ] && [ $1 -le 19 ]; then
		lvl=$1
	fi
	
	spd=$(echo "scale=1;1/$lvl" | bc)
	dif=$((15-$lvl))
	trap quit SIGINT

	s=$RANDOM; let "s %= $((w-16))"
	gen_empty_road
	px=$((s+8))

	main
}

quit() {
	echo -e "\033[?25h"
	stty echo
	echo ""
	tput cup $h 0;
	exit 0
}

main() {
	while true; do
		tput cup 0 0
		p=$RANDOM; let "p %= 3"
		if [ $p -eq 2 ]; then
			p="-1"
		fi
		s=$((s-p))
		if [ $s -lt 2 ]; then
			s=2
		elif [ $s -gt $((w-19)) ]; then
			s=$((w-18))
		fi
		
		gen_road $s

		screen=$(echo -n "$screen" | head -$((h-1)))
		
		#TODO: levels
		read -s -t$spd -n1 key
		case $key in
			$KEY_LEFT)	px=$((px-1));;
			$KEY_RIGHT)	px=$((px+1));;
		esac

		echo -n "$screen"
		ll=$(echo -n "$screen" | tail -1)
		pp=$(echo $ll | cut -c$((px+1))-$((px+1)))
		case $pp in
			"|")	quit;;
			"0")	quit;;
			*)		tput cup $((h-2)) $px; echo -n "H";;
		esac
	
	score=$((score+$lvl*2))
	tput cup $((h-1)) 1; echo -ne "Score:\t$score"
	done
	
}

init $1
