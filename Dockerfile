FROM centos:7

### Prepare yum repos
RUN rpmkeys --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    yum --assumeyes install epel-release && \
    rpmkeys --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 && \
### Install dumb-init
    yum --assumeyes install wget && \
    wget --output-document /usr/local/bin/dumb-init \
         https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64 && \
    chmod +x /usr/local/bin/dumb-init && \
    yum --assumeyes remove wget && \
### Install iRODS resource server
    yum --assumeyes install \
        which \
        https://files.renci.org/pub/irods/releases/4.1.10/centos7/irods-resource-4.1.10-centos7-x86_64.rpm && \
    mkdir /var/lib/irods/.irods && \
    adduser --system --comment 'iRODS Administrator' --home-dir /var/lib/irods --shell /bin/bash \
            irods && \
    chown --recursive irods:irods /etc/irods /var/lib/irods && \
### Install iRODS management script dependencies
    yum --assumeyes install jq sysvinit-tools && \
### Clear yum cache for smaller image
    yum --assumeyes clean all && \
    rm --force --recursive /var/cache/yum

### Install iRODS management script
COPY run-irods.sh /run-irods
RUN chown irods:irods /run-irods && \
    chmod ug+x /run-irods

WORKDIR /var/lib/irods

USER irods

ENV IRODS_CLERVER_PASSWORD=rods

ENTRYPOINT [ "/usr/local/bin/dumb-init", "--", "/run-irods" ]
