#Add in DockerFile
COPY pre-conf.sh /sbin/tzDateConfigure.sh
RUN chmod +x /sbin/tzDateConfigure.sh; sync \
    && /bin/bash -c /sbin/tzDateConfigure.sh \
    && rm /sbin/tzDateConfigure.sh
    
#Information references
https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
