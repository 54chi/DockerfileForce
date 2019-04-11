FROM jenkins/jenkins:lts-alpine
MAINTAINER 54chi

# based on anyei/jenkins-to-salesforce (last updated on 2015)
# and https://github.com/carlossg/docker-maven
# the jenkins alpine is based on the jdk container and comes with: git, openssh-client, curl, unzip, bash, ttf-dejavu and coreutils

# From Jenkins alpine, these env will be set
# ENV JENKINS_HOME /var/jenkins_home
# ENV JENKINS_SLAVE_AGENT_PORT 50000

# From {version}-jdk-alpine used by Jenkins alpine, these will be set (e.g. for 1.8)
# ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
# ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

ENV ANT_VERSION 1.10.1
ENV MVN_VERSION=3.6.0
ENV SF_VERSION 40.0

# Changing to root, it was running on jenkins user context
USER root

RUN mkdir /var/log/jenkins
RUN mkdir /var/cache/jenkins
RUN mkdir /usr/share/jenkins/ref/plugins

#INSTALLING MAVEN
RUN apk --update add tar \
    && curl -sSL "https://apache.osuosl.org/maven/maven-3/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz" | tar -xzf - -C /usr/lib/  \
    && mv /usr/lib/apache-maven* /usr/lib/maven \
    && ln -s /usr/lib/maven/bin/mvn /usr/bin/mvn

#INSTALLING ANT
  RUN mkdir -p /var/ant_home
  ADD http://archive.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.zip /var/ant_home/apache-ant-${ANT_VERSION}-bin.zip
  RUN unzip /var/ant_home/apache-ant-${ANT_VERSION}-bin.zip -d /var/ant_home && rm /var/ant_home/apache-ant-${ANT_VERSION}-bin.zip
  ENV ANT_HOME=/var/ant_home/apache-ant-${ANT_VERSION}
  ENV PATH=${PATH}:${ANT_HOME}/bin

#INSTALLING SALESFORCE ANT PLUGIN
  RUN mkdir ${ANT_HOME}/lib/x
  ADD https://gs0.salesforce.com/dwnld/SfdcAnt/salesforce_ant_${SF_VERSION}.zip ${ANT_HOME}/lib/x/salesforce_ant_${SF_VERSION}.zip
  RUN unzip ${ANT_HOME}/lib/x/salesforce_ant_${SF_VERSION}.zip -d ${ANT_HOME}/lib/x && cp ${ANT_HOME}/lib/x/ant-salesforce.jar ${ANT_HOME}/lib/ant-salesforce.jar && rm -rf ${ANT_HOME}/lib/x

  RUN chown -R jenkins:jenkins "${ANT_HOME}" "/usr/share/jenkins/ref/plugins"
  RUN chown -R jenkins:jenkins /var/log/jenkins
  RUN chown -R jenkins:jenkins /var/cache/jenkins

# SOME CLEANING
  RUN rm -rf /var/cache/apk/* /tmp/*
  
# Changing to jenkins, it was running on root user context
USER jenkins
ENV JAVA_OPTS="-Xmx4096m"

# INSTALLING PLUGINS
COPY plugins.txt /var/jenkins_home/plugins.txt
RUN /usr/local/bin/plugins.sh /var/jenkins_home/plugins.txt
RUN echo 2.0 > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state

# Put the log file into the log directory, which will be in the data volume
# Move the WAR out of the persisted jenkins data dir
ENV JENKINS_OPTS="--logfile=/var/log/jenkins/jenkins.log --webroot=/var/cache/jenkins/war"
