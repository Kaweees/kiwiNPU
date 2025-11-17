FROM hpretl/iic-osic-tools

USER root
RUN mkdir /home/asic
RUN chown 1000 /home/asic
RUN cp -r ~/.bashrc /home/asic/ &&\
    cat /etc/skel/.bashrc >> /home/asic/.bashrc &&\
    echo "cd ~/workspace" >>  /home/asic/.bashrc
ENV HOME=/home/asic

