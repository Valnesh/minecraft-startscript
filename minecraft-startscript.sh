#!/bin/sh

# Minecraftserver startscript
#Serververzeichnis
dir=/home/minecraft/vanilla

#name des screens
screen=vanilla

#name der mc-jar
jar=minecraft_server.14w34d.jar

#backupverzeichnis
backup=/home/minecraft/backup/vanilla

#speicherdauer der backups in tagen
days=21

#########################################

#aktuelles datum
date=$(date +%F-%H-%M)

do_start() {
        cd $dir
	screen -L -d -m -S $screen java -server -Xmx4096m -jar $jar nogui
}

do_stop() {
	screen -S $screen -X stuff 'stop\n'
}

do_restart() {
	do_stop
	sleep 60
	do_start
}

do_backup() {
	screen -S $screen -X stuff 'say Backup startet\n'
	screen -S $screen -X stuff 'save-off\n'
	screen -S $screen -X stuff 'save-all\n'
	rm -rf $dir/backup/
	cp -r $dir/world/ $dir/backup/
	screen -S $screen -X stuff 'save-on\n'
}

do_archive() {
	tar -czf $backup/${screen}_$date.tar.gz $dir/backup/
	rm $backup/${screen}_lastbackup.txt
	touch $backup/${screen}_lastbackup.txt
	echo $date > $backup/${screen}_lastbackup.txt
}

do_clean() {
	cd $backup
	ls -t1 | tail -n +$days | xargs rm
	cd $dir
	rm $dir/screenlog.0
	touch $dir/screenlog.0
	screen -S $screen -X stuff 'say Backup fertig\n'
}

do_check() {
#MODPACK ONLY
screen -S $screen -X stuff 'list\n'
sleep 10
ONLINE=$(grep online $dir/screenlog.0 | awk {'print $6'} | sed '2,999d')
if [ "$ONLINE" != "0/10" ] ;
        then
                do_backup
                do_archive
                do_clean
fi
#MODPACK ONLY

JOINED=$(grep -o "joined the game" $dir/screenlog.0 | sed '2,999d')
if [ "$JOINED" = "joined the game" ] ;
	then
		do_backup
		do_archive
		do_clean
fi

LEFT=$(grep -o "left the game" $dir/screenlog.0 | sed '2,999d')
if [ "$LEFT" = "left the game" ] ;
	then
		do_backup
		do_archive
		do_clean
fi
}

case "$1" in
        start)
			do_start
        ;;
        restart)
			do_restart
        ;;
        stop)
			do_stop
        ;;
        backup)
			do_check
        ;;
        *)
			echo "Usage: /etc/init.d/minecraft {start|stop|restart|backup}"
			exit 1
        ;;
esac
