function welcome() {
	h=`date +%H`
	if [ $h -lt 04 ] || [[ $h -gt 22 ]];
    	then greeting="Good Night"
  	elif [ $h -lt 12 ];
    	then greeting="Good Morning"
  	elif [ $h -lt 18 ];
    	then greeting="Good Afternoon"
  	elif [ $h -lt 22 ];
    	then greeting="Good Evening"
  	else
    	greeting="Hello"
  	fi

	echo $greeting | figlet -f invita | lolcat
}

function system_info() {
	neofetch \
      --disable model resolution shell de wm wm_theme theme icons distro kernel cpu gpu \
      --backend off \
      --color_blocks off \
      --memory_display info
}

function more_info() {
	timeout=0.5
	
	# Print date time
	echo -e "$(date '+🗓️  Date: %A, %B %d, %Y at %H:%M')"

	# Print local weather
	curl -s -m $timeout "wttr.in?format=%cWeather:+%C+%t,+%w"

	echo -e "\n"
}

welcome
system_info
more_info

# EOF