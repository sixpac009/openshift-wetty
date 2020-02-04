FROM registry.access.redhat.com/ubi8/ubi:latest

ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk \
    HOME=/opt/workspace

# Copy entitlements
COPY ./etc-pki-entitlement /etc/pki/entitlement
# Copy subscription manager configurations
COPY ./rhsm-conf /etc/rhsm
COPY ./rhsm-ca /etc/rhsm/ca

RUN rm /etc/rhsm-host && \
    yum repolist --disablerepo=* && \
    subscription-manager repos \
    --enable rhel-8-for-x86_64-appstream-rpms \ 
    --enable rhel-8-for-x86_64-baseos-rpms \
    --enable rhel-8-for-x86_64-supplementary-rpms && \
    yum install -y --setopt=tsflags=nodocs \
        make \
        nmap-ncat \
        nodejs \
        gcc-c++ \
        git \
        #atomic-openshift-clients \
        openssl \
        unzip \
        java-1.8.0-openjdk-devel \
        openssh-server && \
    yum clean all && \
    rm -rf /var/cache/yum/*
# RUN ln -s /opt/rh/rh-nodejs8/root/usr/bin/node /usr/bin/node \
#   && ln -s /opt/rh/rh-nodejs8/root/usr/bin/npm /usr/bin/npm
# ADD http://mirrors.gigenet.com/apache/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.zip /root/apache-maven-3.5.2-bin.zip
ADD https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.5.2/apache-maven-3.5.2-bin.zip /root/apache-maven-3.5.2-bin.zip
RUN cd /root && \
    unzip /root/apache-maven-3.5.2-bin.zip && \
    mv apache-maven-3.5.2 /usr/bin/

COPY rhel-profile.sh /etc/profile.d/
RUN chmod a+r /etc/profile.d/rhel-profile.sh

# RUN mkdir /home/default 
RUN useradd -u 2000 default
RUN ls -l /etc/shadow
RUN chmod 0640 /etc/shadow
# RUN echo ${WETTY_PASSWORD} | passwd default --stdin
RUN echo default:default | chpasswd
#RUN chown default:default /home/default

RUN /usr/bin/ssh-keygen -A -N '' && \
    chmod -R a+r /etc/ssh/* && \
    # rm /run/nologin && \
    /usr/sbin/setcap 'cap_net_bind_service=+ep' /usr/sbin/sshd

EXPOSE 22
WORKDIR /home/default
USER default

CMD ["/usr/sbin/sshd", "-D", "-p", "22", "-E", "/home/default/ssh.log"]
