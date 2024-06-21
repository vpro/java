FROM eclipse-temurin:21.0.2_13-jdk-jammy
 
ARG CI_COMMIT_SHA
ARG CI_COMMIT_REF_NAME
ARG CI_COMMIT_TITLE
ARG CI_COMMIT_TIMESTAMP


# This makes ${USER.HOME} /
ENV HOME /
# Handy, on a new shell you'll be in the directory of interest
WORKDIR /app

COPY rds-ca-2019-root.der $JAVA_HOME/lib/security

# - make the mount points and fill with example content which can be used when docker image is ran locally
# - install some useful tools
# -   rsync: avoid warnings for oc rsync
# -   curl: I forgot when this is needed, usefull for debugging. curl http://localhost:8080
# -   dnsutils: for debugging it's usefull to have tools like 'host' available.
# -   less, ncal: just for debugging, inspecting log files
# -   procps: just for debugging. 'ps'.
# -   psmisc: just for debugging. 'pstree'
# -   netcat: just for debugging. 'nc'.
# -   apache2-utils: we use rotatelogs to rotate catalina.out


RUN set -eux && \
  apt-get update && apt-get -y upgrade && \
  apt-get -y install less ncal procps curl rsync dnsutils  netcat apache2-utils  vim-tiny psmisc inotify-tools gawk && \
  keytool -importcert -alias rds-root -keystore ${JAVA_HOME}/lib/security/cacerts -storepass changeit -noprompt -trustcacerts -file $JAVA_HOME/lib/security/rds-ca-2019-root.der && \
  mkdir -m 775 -p /conf /app 

COPY rds-ca-2019-root.pem /conf

# Have a workable shell
SHELL ["/bin/bash", "-c"]

ENV TZ=Europe/Amsterdam
ENV HISTFILE=/data/.bash_history
ENV PSQL_HISTORY=/data/.pg_history
ENV PSQL_EDITOR=/usr/bin/vi
ENV LESSHISTFILE=/data/.lesshst

# 'When invoked as an interactive shell with the name sh, Bash looks for the variable ENV, expands its value if it is defined, and uses the expanded value as the name of a file to read and execute'
ENV ENV=/.binbash
COPY binbash /.binbash

# - Setting up timezone and stuff
RUN echo "dash dash/sh boolean false" | debconf-set-selections &&  DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash && \
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
  dpkg-reconfigure --frontend noninteractive tzdata && \
  ln -s /tmp /data


# With bearable key bindings:
COPY inputrc /etc
# And a nicer bash prompt
COPY bashrc /.bashrc
# ' Failed to source defaults.vim' (even an empty vi config file like that avoid it)
COPY exrc /.exrc


ENTRYPOINT ["java", "-jar", "/app/app.war"]

RUN echo '#this file is hidden in openshift\nenv=localhost' > /conf/application.properties && \
  (echo -e "vpro/java git version=${CI_COMMIT_SHA}\t${CI_COMMIT_REF_NAME}\t${CI_COMMIT_TIMESTAMP}\t${CI_COMMIT_TITLE}") > /DOCKER.BUILD && \
  (echo -n "vpro/java build time=" ; date -Iseconds) >> /DOCKER.BUILD
  
# The onbuild commands to install the application when this image is overlaid

ONBUILD ARG PROJECT_VERSION
ONBUILD ARG NAME

ONBUILD ARG COPY_TESTS
ONBUILD ARG CI_COMMIT_REF_NAME
ONBUILD ARG CI_COMMIT_SHA
ONBUILD ARG CI_COMMIT_TITLE
ONBUILD ARG CI_COMMIT_TIMESTAMP
ONBUILD ADD target/*${PROJECT_VERSION}.war /app/app.war

 
ONBUILD LABEL version="${PROJECT_VERSION}"
ONBUILD LABEL maintainer=digitaal-techniek@vpro.nl

# We need regular security patches. E.g. on every build of the application
ONBUILD RUN apt-get update && apt-get -y upgrade && \
  (echo "${NAME} version=${PROJECT_VERSION}") >> /DOCKER.BUILD && \
  (echo -e "${NAME} git version=${CI_COMMIT_SHA}\t${CI_COMMIT_REF_NAME}\t${CI_COMMIT_TIMESTAMP}\t${CI_COMMIT_TITLE}") >> /DOCKER.BUILD && \
  (echo -n "${NAME} build time=" ; date -Iseconds) >> /DOCKER.BUILD
    
  

