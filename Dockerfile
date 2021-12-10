FROM centos:7

### Install dumb-init
ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64 \
    /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

### Install iRODS resource server
ADD https://packages.irods.org/renci-irods.yum.repo /etc/yum.repos.d/renci-irods.yum.repo
RUN rpm --import https://packages.irods.org/irods-signing-key.asc && \
    rpmkeys --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    yum --assumeyes install epel-release && \
    rpmkeys --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 && \
    yum --assumeyes install irods-server-4.2.8 && \
### Installing undocumented 4.2.8 dependency, unixODBC
    yum --assumeyes install unixODBC && \
### Install iRODS management script dependencies
    yum --assumeyes install jq sysvinit-tools && \
### Clear yum cache for smaller image
    yum --assumeyes clean all && \
    rm --force --recursive /var/cache/yum && \
### Initialize server
    adduser --system --comment 'iRODS Administrator' --home-dir /var/lib/irods --shell /bin/bash \
      irods && \
    jq ".installation_time |= \"$(date '+%Y-%m-%dT%T.%6N')\"" /var/lib/irods/VERSION.json.dist \
      > /var/lib/irods/VERSION.json && \
    mkdir /var/lib/irods/.irods && \
    chown --recursive irods:irods /etc/irods /var/lib/irods

### Install iRODS management script
COPY run-irods.sh /run-irods
RUN chown irods:irods /run-irods && \
    chmod ug+x /run-irods

WORKDIR /var/lib/irods

USER irods

ENV IRODS_CLERVER_PASSWORD=rods

ENTRYPOINT [ "/usr/local/bin/dumb-init", "--", "/run-irods" ]
