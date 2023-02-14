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

welcome

# EOF