/bin/bash
set -x
 if [ $# -gt 0 ]
 then
 # let use the given full path config (.conf) file
    . $1
 else
 # Application specific
    . $(dirname $0)/rsyncbackup.conf
 fi

 while read line
 do
    REMOTE_DIR="$REMOTE_DIR $line"
    shift
 done < $LIST

 if [ ! -e $APPLICATION_DIR/$PID_FILE ]
 then
  # Script pre-backup
    if [ -f $PRESCRIPT ]
    then
       $PRESCRIPT
       if [ $? -ne 0 ]
       then
          exit 1
       fi
    fi
    echo $$ > $APPLICATION_DIR/$PID_FILE
    /usr/bin/logger "Sauvegarde rsync $SERVERNAME"
    if [ -e  $APPLICATION_DIR/$LOG_FILE ]
    then
         mv $APPLICATION_DIR/$LOG_FILE $APPLICATION_DIR/$LOG_FILE.0
    fi
    echo "Sauvegarde rsync $SERVERNAME" > $APPLICATION_DIR/$LOG_FILE
    #Boucle de backup
    ERROR_FLAG=0
    ERROR=0
    ERRORS="ERREURS: "
    for rdir in $(echo $REMOTE_DIR)
    do
       if [ ! "x$EXCLUDE" == "x" ]
       then
          EXCLUDE_OPT=""
          while read line
          do
             if [[ $line =~ ^$rdir ]]
             then
                EX=$(basename $line $rdir)
                EXCLUDE_OPT="$EXCLUDE_OPT --exclude=/$EX"
             fi
             shift
          done < $EXCLUDE
       fi
       # rsync
       date >> $APPLICATION_DIR/$LOG_FILE
       echo >> $APPLICATION_DIR/$LOG_FILE
       echo RSYNC BACKUP OF $rdir >> $APPLICATION_DIR/$LOG_FILE
       if [ $LOCAL -eq 1 ]
       then
          echo rsync $RSYNC_OPTS $EXCLUDE_OPT ${rdir}/ ${BCK_DIR}$rdir/ >> $APPLICATION_DIR/$LOG_FILE
          /usr/bin/rsync $RDIFF_OPTS $EXCLUDE_OPT ${rdir}/ ${BCK_DIR}$rdir/ >>  $APPLICATION_DIR/$LOG_FILE 2>&1
       else
          echo rsync $RSYNC_OPTS $EXCLUDE_OPT ${rdir}/ $SERVERUSR@$SERVERIP:${BCK_DIR} >> $APPLICATION_DIR/$LOG_FILE
          #/usr/bin/rsync $RSYNC_OPTS $EXCLUDE_OPT ${rdir}/ $SERVERUSR@$SERVERIP:${BCK_DIR}$rdir/ >>  $APPLICATION_DIR/$LOG_FILE 2>&1
          /usr/bin/rsync $RSYNC_OPTS $EXCLUDE_OPT ${rdir}/ $SERVERIP::${BCK_DIR} >>  $APPLICATION_DIR/$LOG_FILE 2>&1
       fi
       ERROR=$?
       if [ $ERROR -ne 0 ]
       then
          ERRORS="$ERRORS $BASE=$ERROR:"
          ERROR_FLAG=1
       fi
    done
    if [ $ERROR_FLAG -eq 1 ]
    then
       (echo $ERRORS
        date
        echo Voir $APPLICATION_DIR/$LOG_FILE
        grep -i warning $APPLICATION_DIR/$LOG_FILE
        grep -i error $APPLICATION_DIR/$LOG_FILE
       )| mail -s "ERREUR BACKUP SUR $SERVERNAME $(date +%d/%m)" $MAIL_ADMIN
    else
       (date
        ls -l $APPLICATION_DIR/$LOG_FILE
       )|cat $APPLICATION_DIR/$LOG_FILE | mail -s "Sauvegarde sur $SERVERNAME $(date +%d/%m/%Y) terminee" $MAIL_ADMIN
    fi
    date >> $APPLICATION_DIR/$LOG_FILE
    /usr/bin/logger "FIN rsync $SERVERNAME"
    rm -f $APPLICATION_DIR/$PID_FILE
 else
     (echo "$HOSTNAME:$APPLICATION_DIR/$PID_FILE existe : abandon de $0") | mail -s "Erreur sur backup $SERVERNAME" $MAIL_ADMIN
 fi
