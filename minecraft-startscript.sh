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
	screen -L -d -m -S $screen java -server -Xmx4096m -jar $jar nogui
}

do_stop() {
	screen -S $screen -X stuff 'stop\n'
}

do_restart() {
	do_stop
	sleep 10
	do_start
}

do_backup() {
	screen -S $screen -X stuff 'say Backup startet\n'
	screen -S $screen -X stuff 'save-off\n'
	screen -S $screen -X stuff 'save-all\n'
	rm -rf $dir/backup/
	cp -r $dir/world/ $dir/backup/
	screen -S $screen -X stuff 'save-on\n'
	screen -S $screen -X stuff 'say Backup fertig\n'
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
}

do_ftp() {
	lftp -c "open -u USER,PASSWORD HOST; mirror -c -e -R $backup /minecraft/$screen"
}


do_check() {
JOINED=$(grep -o "joined the game" $dir/screenlog.0 | sed '2,999d')
if [ "$JOINED" = "joined the game" ] ;
	then
		do_backup
		do_archive
		do_clean
		do_ftp
fi

LEFT=$(grep -o "left the game" $dir/screenlog.0 | sed '2,999d')
if [ "$LEFT" = "left the game" ] ;
	then
		do_backup
		do_archive
		do_clean
		do_ftp
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
