#!/bin/bash

#Files
declare -r FILE="pacman.csv"

#Keybindings
declare -r LEFT_KEY='a'
declare -r RIGHT_KEY='d'
declare -r UP_KEY='w'
declare -r DOWN_KEY='s'
declare -r QUIT_KEY='q'

#Common
declare -A map
declare key=
declare score=0
declare dots=0
declare Mode=0	#0 - Scatter, 1 - Chase
declare ModeIterations=9
declare ModeCount=7

#Player related variables
declare PDirection=3 #1 - up, 2 - down, 3 - left, 4 - right
declare PBuffer=0
declare PX=24
declare PY=14
declare Energizer=0
declare EngCountdown=0
declare Eaten=200

#Blinky related variables
declare BlinkyX=12
declare BlinkyY=14
declare BlinkyDirection=3
declare BlinkyBuffer=0
declare BlinkyWasEaten=0

#Pinky related variables
declare PinkyX=16
declare PinkyY=13
declare PinkyDirection=3
declare PinkyBuffer=0
declare PinkyWasEaten=0

#Inky related variables
declare InkyX=16
declare InkyY=15
declare InkyDirection=3
declare InkyBuffer=0
declare InkyWasEaten=0

#Clyde related variables
declare ClydeX=16
declare ClydeY=17
declare ClydeDirection=3
declare ClydeBuffer=0
declare ClydeWasEaten=0

render() {
	local bg_blk='\e[40m'
	local bg_blu='\e[44m'
	local bg_yel='\e[43m'
	local bg_red='\e[41m'
	local bg_pur='\e[45m'
	local bg_cyn='\e[46m'
	local bg_lrd='\e[42m'
	local tx_yel='\e[0;33m'
	local tx_red='\e[0;31m'
	local txtrst='\e[0m'
	case $1 in
		0) local obj="$bg_blk $txtrst";;		#empty space
		1) local obj="$bg_blu $txtrst";;		#wall
		2) local obj="$bg_yel▒$txtrst";;		#player
		3) local obj="$bg_blk $txtrst";;		#teleport
		4) local obj="$tx_yel$bg_blk◦$txtrst";;	#dot
		5) local obj="$tx_yel$bg_blk▪$txtrst";;	#energizer
		6) local obj="$bg_red $txtrst";;		#Blinky
		7) local obj="$bg_pur $txtrst";;		#Pinky
		8) local obj="$bg_cyn $txtrst";;		#Inky
		9) local obj="$bg_lrd $txtrst";;		#Clyde
		10) local obj="${bg_blu}G$txtrst";;		#Frightened Ghost
	esac
	echo -en $obj
}

#set value to cell on map
smap() {
	map[a${1}_${2}]=$3
}

#get value from cell on map
gmap() {
	if [ -z ${map[a${1}_${2}]} ]; then
		local result=0
	else
		local result=${map[a${1}_${2}]}
	fi
	echo $result
}

#game initialization - loading map, getting start positions of ghosts
init() {
	clear
	stty -echo
	OLD_IFS=$IFS
	IFS=,
	for ((i=1; $i <= $(cat $FILE | wc -l); i=i+1)); do
		field[$i]=$(sed ${i}q\;d $FILE)
	done
	for ((x=1; $x <= ${#field[@]}; x=x+1)); do
		row=${field[$x]}
		y=0
		for cell in $row; do
			tput cup $x $((y+1)) && render $cell
			smap $x $((y+1)) $cell

			if [ $cell -eq 4 ] || [ $cell -eq 5 ]; then
				dots=$((dots+1))
			fi
			y=$((y+1))
		done
	done
	IFS=$OLD_IFS
	
	#hide cursor
	echo -e "\033[?25l"
	
	main
}

#Player moving
PStep() {
	tput cup $PX $PY 
	render 0
	if [ $(gmap $PX $PY) -eq 3 ]; then
		if [ $PY -eq 1 ]; then
			PY=27
		else
			PY=2
		fi
	fi

	case $PDirection in
	#up
	1)	x=$((PX-1))
		if [ $(gmap $x $PY) -ne 1 ]; then
			PX=$((PX-1))
			PBuffer=$PDirection
		else
			case $PBuffer in
			4)	y=$((PY+1))
				if [ $(gmap $PX $y) -ne 1 ]; then
					PY=$((PY+1))
				fi;;
			3)	y=$((PY-1))
				if [ $(gmap $PX $y) -ne 1 ]; then
					PY=$((PY-1))
				fi;;
			2)	x=$((PX+1))
				if [ $(gmap $x $PY) -ne 1 ]; then
					PX=$((PX+1))
				fi;;
			*);;
			esac
		fi;;
	#down
	2)      x=$((PX+1))
		if [ $(gmap $x $PY) -ne 1 ]; then
			PX=$((PX+1))
			PBuffer=$PDirection
		else
			case $PBuffer in
			4)	y=$((PY+1))
				if [ $(gmap $PX $y) -ne 1 ]; then
					PY=$((PY+1))
				fi;;
			3)	y=$((PY-1))
				if [ $(gmap $PX $y) -ne 1 ]; then
					PY=$((PY-1))
				fi;;
			1)	x=$((PX-1))
				if [ $(gmap $x $PY) -ne 1 ]; then
					PX=$((PX-1))
				fi;;
			*);;
			esac
		fi;;
	#left
	3)	y=$((PY-1))
		if [ $(gmap $PX $y) -ne 1 ]; then
			PY=$((PY-1))
			PBuffer=$PDirection
		else
			case $PBuffer in
			4)	y=$((PY+1))
				if [ $(gmap $PX $y) -ne 1 ]; then
					PY=$((PY+1))
				fi;;
			1)	x=$((PX-1))
				if [ $(gmap $x $PY) -ne 1 ]; then
					PX=$((PX-1))
				fi;;
			2)	x=$((PX+1))
				if [ $(gmap $x $PY) -ne 1 ]; then
					PX=$((PX+1))
				fi;;
			*);;
			esac
		fi;;
	#right
	4)	y=$((PY+1))
		if [ $(gmap $PX $y) -ne 1 ]; then
			PY=$((PY+1))
			PBuffer=$PDirection
		else
			case $PBuffer in
			3)	y=$((PY-1))
				if [ $(gmap $PX $y) -ne 1 ]; then
					PY=$((PY-1))
				fi;;
			1)	x=$((PX-1))
				if [ $(gmap $x $PY) -ne 1 ]; then
					PX=$((PX-1))
				fi;;
			2)	x=$((PX+1))
				if [ $(gmap $x $PY) -ne 1 ]; then
					PX=$((PX+1))
				fi;;
			*);;
			esac
		fi;;
	esac
	tput cup $PX $PY
	render 2
}

#Moving of ghosts while energizer active
FrightenedStep() {
	local GhostName="$1"
	eval "local GhostX=\$${GhostName}X"
	eval "local GhostY=\$${GhostName}Y"
	eval "local GhostDirection=\$${GhostName}Direction"
	eval "local GhostBuffer=\$${GhostName}Buffer"
	
	local x=$GhostX
	local y=$GhostY
	local d=$RANDOM; let "d %= 4"
	if [ $d -ne 0 ]; then
		GhostDirection=$d
	fi
	case $GhostDirection in
	1)	if [ $(gmap $((x-1)) $y) -ne 1 ]; then
			GhostX=$((x-1))
		fi;;
	2)	if [ $(gmap $((x+1)) $y) -ne 1 ]; then
			GhostX=$((x+1))
		fi;;
	3)	if [ $(gmap $x $(($y-1))) -ne 1 ]; then
			GhostY=$((y-1))
		fi;;
	4)	if [ $(gmap $x $(($y+1))) -ne 1 ]; then
			GhostY=$((y+1))
		fi;;
	esac
	if [ $x -ne $GhostX ] || [ $y -ne $GhostY ]; then
		tput cup $x $y
		render $GhostBuffer
		GhostBuffer=$(gmap $GhostX $GhostY)
		tput cup $GhostX $GhostY
		render 10
	fi

	if [ $(gmap $GhostX $GhostY) -eq 3 ]; then
		if [ $GhostY -eq 1 ]; then
			GhostY=27
			GhostDirection=3
		else
			GhostY=2
			GhostDirection=4
		fi
	fi
	
	eval "${GhostName}X=$GhostX"
	eval "${GhostName}Y=$GhostY"
	eval "${GhostName}Buffer=$GhostBuffer"
	eval "${GhostName}Direction=$GhostDirection"
}

#Ghost move
#GhostName TargetX TargetY
GhostStep() {
	local GhostName=$1
	eval "local GhostX=\$${GhostName}X"
	eval "local GhostY=\$${GhostName}Y"
	eval "local GhostDirection=\$${GhostName}Direction"
	eval "local GhostBuffer=\$${GhostName}Buffer"
	case $GhostName in
		Blinky)	local GhostID=6;;
		Pinky)	local GhostID=7;;
		Inky)	local GhostID=8;;
		Clyde)	local GhostID=9;;
	esac
	local TargetX=$2
	local TargetY=$3
	#length of vectors
	local Vect1=999
	local Vect2=999
	local Vect3=999
	case $GhostDirection in
	#up
	1)	if [ $(gmap $((GhostX-1)) $GhostY) -ne 1 ]; then
			Vect1=$(echo "scale=2;sqrt(($TargetX-($GhostX-1))^2+($TargetY-$GhostY)^2)" | bc ) #1
		fi
		if [ $(gmap $GhostX $((GhostY+1))) -ne 1 ]; then
			Vect2=$(echo "scale=2;sqrt(($TargetX-$GhostX)^2+($TargetY-($GhostY+1))^2)" | bc ) #4
		fi
		if [ $(gmap $GhostX $((GhostY-1))) -ne 1 ]; then
			Vect3=$(echo "scale=2;sqrt(($TargetX-$GhostX)^2+($TargetY-($GhostY-1))^2)" | bc ) #3
		fi
		if [[ $Vect1 < $Vect2 ]]; then
			if [[ $Vect1 < $Vect3 ]]; then
				GhostDirection=1
			else
				GhostDirection=3
			fi
		elif [[ $Vect3 < $Vect2 ]]; then
			GhostDirection=3
		else
			GhostDirection=4
		fi;;
	#down
	2)	if [ $(gmap $((GhostX+1)) $GhostY) -ne 1 ]; then
			Vect1=$(echo "scale=2;sqrt(($TargetX-($GhostX+1))^2+($TargetY-$GhostY)^2)" | bc ) #2
		fi
		if [ $(gmap $GhostX $((GhostY+1))) -ne 1 ]; then
			Vect2=$(echo "scale=2;sqrt(($TargetX-$GhostX)^2+($TargetY-($GhostY+1))^2)" | bc ) #4
		fi
		if [ $(gmap $GhostX $((GhostY-1))) -ne 1 ]; then
			Vect3=$(echo "scale=2;sqrt(($TargetX-$GhostX)^2+($TargetY-($GhostY-1))^2)" | bc ) #3
		fi
		if [[ $Vect1 < $Vect2 ]]; then
			if [[ $Vect1 < $Vect3 ]]; then
				GhostDirection=2
			else
				GhostDirection=3
			fi
		elif [[ $Vect3 < $Vect2 ]]; then
			GhostDirection=3
		else
			GhostDirection=4
		fi;;
	#left
	3)	if [ $(gmap $GhostX $((GhostY-1))) -ne 1 ]; then
			Vect1=$(echo "scale=2;sqrt(($TargetX-$GhostX)^2+($TargetY-($GhostY-1))^2)" | bc ) #3
		fi
		if [ $(gmap $((GhostX+1)) $GhostY) -ne 1 ]; then
			Vect2=$(echo "scale=2;sqrt(($TargetX-($GhostX+1))^2+($TargetY-$GhostY)^2)" | bc ) #2
		fi
		if [ $(gmap $((GhostX-1)) $GhostY) -ne 1 ]; then
			Vect3=$(echo "scale=2;sqrt(($TargetX-($GhostX-1))^2+($TargetY-$GhostY)^2)" | bc ) #1
		fi
		if [[ $Vect1 < $Vect2 ]]; then
			if [[ $Vect1 < $Vect3 ]]; then
				GhostDirection=3
			else
				GhostDirection=1
			fi
		elif [[ $Vect3 < $Vect2 ]]; then
			GhostDirection=1
		else
			GhostDirection=2
		fi;;
	#right
	4)	if [ $(gmap $GhostX $((GhostY+1))) -ne 1 ]; then
			Vect1=$(echo "scale=2;sqrt(($TargetX-$GhostX)^2+($TargetY-($GhostY+1))^2)" | bc ) #4
		fi
		if [ $(gmap $((GhostX+1)) $GhostY) -ne 1 ]; then
			Vect2=$(echo "scale=2;sqrt(($TargetX-($GhostX+1))^2+($TargetY-$GhostY)^2)" | bc ) #2
		fi
		if [ $(gmap $((GhostX-1)) $GhostY) -ne 1 ]; then
			Vect3=$(echo "scale=2;sqrt(($TargetX-($GhostX-1))^2+($TargetY-$GhostY)^2)" | bc ) #1
		fi
		if [[ $Vect1 < $Vect2 ]]; then
			if [[ $Vect1 < $Vect3 ]]; then
				GhostDirection=4
			else
				GhostDirection=1
			fi
		elif [[ $Vect3 < $Vect2 ]]; then
			GhostDirection=1
		else
			GhostDirection=2
		fi;;
	esac
	tput cup $GhostX $GhostY
	render $GhostBuffer
	if [ $(gmap $GhostX $GhostY) -eq 3 ]; then
		if [ $GhostY -eq 1 ]; then
			GhostY=27
			GhostDirection=3
		else
			GhostY=2
			GhostDirection=4
		fi
	fi
	case $GhostDirection in
		1) GhostX=$((GhostX-1));;
		2) GhostX=$((GhostX+1));;
		3) GhostY=$((GhostY-1));;
		4) GhostY=$((GhostY+1));;
	esac
	GhostBuffer=$(gmap $GhostX $GhostY)
	tput cup $GhostX $GhostY
	render $GhostID
	eval "${GhostName}X=$GhostX"
	eval "${GhostName}Y=$GhostY"
	eval "${GhostName}Buffer=$GhostBuffer"
	eval "${GhostName}Direction=$GhostDirection"
}


#moving of red ghost
BlinkyStep() {
	if [ $Mode -eq 1 ]; then
		GhostStep Blinky $PX $PY
	else
		GhostStep Blinky -3 23
	fi
}

#moving of pink ghost
PinkyStep() {
	if [ $Mode -eq 1 ]; then
		case $PDirection in
			1)	local x=$((PX-2))
				local y=$PY;;
			2)	local x=$((PX+2))
				local y=$PY;;
			3)	local x=$PX
				local y=$((PY-2));;
			4)	local x=$PX
				local y=$((PY+2));;
		esac
		GhostStep Pinky $x $y
	else
		GhostStep Pinky -3 3
	fi
}

#moving of cyan ghost
InkyStep() {
	if [ $Mode -eq 1 ]; then
		case $PDirection in
			1)	local x=$((2*(PX-2)-BlinkyX))
				local y=$((2*PY-BlinkyY));;
			2)	local x=$((2*(PX+2)-BlinkyX))
				local y=$((2*PY-BlinkyY));;
			3)	local x=$((2*PX-BlinkyX))
				local y=$((2*(PY-2)-BlinkyY));;
			4)	local x=$((2*PX-BlinkyX))
				local y=$((2*(PY+2)-BlinkyY));;
		esac
		GhostStep Inky $x $y
	else
		GhostStep Inky 36 27
	fi
}

ClydeStep() {
	if [ $Mode -eq 1 ]; then
		local vect=$(echo "scale=0;sqrt(($PX-$ClydeX)^2+($PY-$ClydeY)^2)" | bc )
		if [ $vect -gt -8 ] && [ $vect -lt 8 ]; then
			GhostStep Clyde $PX $PY
		else
			GhostStep Clyde 36 0
		fi
	else
		GhostStep Clyde 36 0
	fi
}

quit() {
	clear
	echo -e "\033[?25h"
	stty echo
	exit 0
}

#Check situations
controller() {
	
	#Move player
	PStep

	#Mode switching
	if [ $ModeIterations -ne 0 ]; then
		if [ $Mode -eq 0 ]; then
			if [ $ModeCount -ne 0 ]; then
				ModeCount=$((ModeCount-1))
			else
				Mode=1
				ModeCount=20
				ModeIterations=$((ModeIterations-1))
			fi
		elif [ $Mode -eq 1 ]; then
			if [ $ModeCount -ne 0 ]; then
				ModeCount=$((ModeCount-1))
			else
				Mode=0
				ModeCount=7
				ModeIterations=$((ModeIterations-1))
			fi
		fi
	fi

	#Check if player ate dot
	if [ $(gmap $PX $PY) -eq 4 ]; then
		score=$((score+10))
		smap $PX $PY 0
		dots=$((dots-1))
	elif [ $(gmap $PX $PY) -eq 5 ]; then
		score=$((score+50))
		smap $PX $PY 0
		dots=$((dots-1))
		Energizer=1
		EngCountdown=40
		BlinkyWasEaten=0
		PinkyWasEaten=0
		InkyWasEaten=0
		ClydeWasEaten=0
	fi

	##############
	#Ghost moving#
	##############

	#if player ate energizer
	if [ $Energizer -eq 1 ]; then
		EngCountdown=$((EngCountdown-1))

		if [ $EngCountdown -eq 0 ]; then
			Energizer=0
			Eaten=200
		fi
		
		#Blinky
		if [ $BlinkyWasEaten -eq 0 ]; then
			FrightenedStep Blinky
		elif [ $BlinkyWasEaten -eq 1 ]; then
			smap $BlinkyX $BlinkyY $BlinkyBuffer
			BlinkyX=12
			BlinkyY=14
			BlinkyBuffer=0
			BlinkyWasEaten=2
		elif [ $BlinkyWasEaten -eq 2 ]; then
			BlinkyStep
		fi

		#Pinky
		if [ $PinkyWasEaten -eq 0 ]; then
			FrightenedStep Pinky
		elif [ $PinkyWasEaten -eq 1 ]; then
			smap $PinkyX $PinkyY $PinkyBuffer
			PinkyX=16
			PinkyY=13
			PinkyBuffer=0
			PinkyWasEaten=2
		elif [ $PinkyWasEaten -eq 2 ]; then
			PinkyStep
		fi
		
		#Inky
		if [ $InkyWasEaten -eq 0 ]; then
			FrightenedStep Inky
		elif [ $InkyWasEaten -eq 1 ]; then
			smap $InkyX $InkyY $InkyBuffer
			InkyX=16
			InkyY=15
			InkyBuffer=0
			InkyWasEaten=2
		elif [ $InkyWasEaten -eq 2 ]; then
			InkyStep
		fi
		
		#Clyde
		if [ $ClydeWasEaten -eq 0 ]; then
			FrightenedStep Clyde
		elif [ $ClydeWasEaten -eq 1 ]; then
			smap $ClydeX $ClydeY $ClydeBuffer
			ClydeX=16
			ClydeY=15
			ClydeBuffer=0
			ClydeWasEaten=2
		elif [ $ClydeWasEaten -eq 2 ]; then
			ClydeStep
		fi
		
		#Blinky
		if [ $PX -eq $BlinkyX ] && [ $PY -eq $BlinkyY ]; then
			score=$((score+Eaten))
			Eaten=$((Eaten*2))
			BlinkyWasEaten=1
			#check if Blinky stands on dot or energizer
			if [ $BlinkyBuffer -eq 4 ] || [ $BlinkyBuffer -eq 5 ]; then
				BlinkyBuffer=0
			fi
		fi
		
		#Pinky
		if [ $PX -eq $PinkyX ] && [ $PY -eq $PinkyY ]; then
			score=$((score+Eaten))
			Eaten=$((Eaten*2))
			PinkyWasEaten=1
			#check if Pinky stands on dot or energizer
			if [ $PinkyBuffer -eq 4 ] || [ $PinkyBuffer -eq 5 ]; then
				PinkyBuffer=0
			fi
		fi
		
		#Inky
		if [ $PX -eq $InkyX ] && [ $PY -eq $InkyY ]; then
			score=$((score+Eaten))
			Eaten=$((Eaten*2))
			InkyWasEaten=1
			#check if Inky stands on dot or energizer
			if [ $InkyBuffer -eq 4 ] || [ $InkyBuffer -eq 5 ]; then
				InkyBuffer=0
			fi
		fi
		
		#Clyde
		if [ $PX -eq $ClydeX ] && [ $PY -eq $ClydeY ]; then
			score=$((score+Eaten))
			Eaten=$((Eaten*2))
			ClydeWasEaten=1
			#check if Clyde stands on dot or energizer
			if [ $ClydeBuffer -eq 4 ] || [ $ClydeBuffer -eq 5 ]; then
				ClydeBuffer=0
			fi
		fi
		
		if [ $BlinkyWasEaten -eq 2 ] && ( [ $PX -eq $BlinkyX ] && [ $PY -eq $BlinkyY ] ); then
			tput cup 18 10; echo "GAME OVER!"
			read -s -n1 key
			quit
		fi
		if [ $PinkyWasEaten -eq 2 ] && ( [ $PX -eq $PinkyX ] && [ $PY -eq $PinkyY ] ); then
			tput cup 18 10; echo "GAME OVER!"
			read -s -n1 key
			quit
		fi
		if [ $InkyWasEaten -eq 2 ] && ( [ $PX -eq $InkyX ] && [ $PY -eq $InkyY ] ); then
			tput cup 18 10; echo "GAME OVER!"
			read -s -n1 key
			quit
		fi
		if [ $ClydeWasEaten -eq 2 ] && ( [ $PX -eq $ClydeX ] && [ $PY -eq $ClydeY ] ); then
			tput cup 18 10; echo "GAME OVER!"
			read -s -n1 key
			quit
		fi
	else
		#Normal Ghost moving
		BlinkyStep
		PinkyStep
		InkyStep
		ClydeStep
		
		if ( [ $PX -eq $BlinkyX ] && [ $PY -eq $BlinkyY ] ); then
			tput cup 18 10; echo "GAME OVER!"
			read -s -n1 key
			quit
		fi
		if ( [ $PX -eq $PinkyX ] && [ $PY -eq $PinkyY ] ); then
			tput cup 18 10; echo "GAME OVER!"
			read -s -n1 key
			quit
		fi
		if ( [ $PX -eq $InkyX ] && [ $PY -eq $InkyY ] ); then
			tput cup 18 10; echo "GAME OVER!"
			read -s -n1 key
			quit
		fi
		if ( [ $PX -eq $ClydeX ] && [ $PY -eq $ClydeY ] ); then
			tput cup 18 10; echo "GAME OVER!"
			read -s -n1 key
			quit
		fi
	fi

	#Player collected all dots
	if [ $dots -eq 0 ]; then
		tput cup 18 11; echo "YOU WIN!"
		read -s -n1 key
		quit
	fi
}

main() {
	while true; do
		read -s -t0.1 -n1 key
		case $key in
			$UP_KEY)	PDirection=1;;
			$DOWN_KEY)	PDirection=2;;
			$LEFT_KEY)	PDirection=3;;
			$RIGHT_KEY)	PDirection=4;;
			$QUIT_KEY)	quit;
		esac
		
		controller
		
		tput cup 0 50; echo "Score: $score    "
	done
}

init
