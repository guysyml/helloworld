FROM ubuntu:15.04
MAINTAINER Vijay <vijay.kumar@bizruntime.com>
ENV SCALA_VERSION 2.11.7
ENV SBT_VERSION 0.13.8
#Oracle Java 8
RUN \
	apt-get update && \
	apt-get -y upgrade && \
	apt-get install -y python-software-properties software-properties-common wget vim curl supervisor && \
	add-apt-repository -y ppa:webupd8team/java && \
	echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
	apt-get update && apt-get install -y oracle-java7-installer 
ENV JAVA_HOME /usr/lib/jvm/java-7-oracle

#Add Bitbucket Authentication
RUN mkdir -p /root/.ssh
ADD id_rsa /root/.ssh/id_rsa
RUN chmod 700 /root/.ssh/id_rsa && \
	echo "Host github.com\n\tStrictHostKeyChecking no\n" > /root/.ssh/config

#Git clone the repository
RUN apt-get install -y git && \
	cd /opt && \
	git clone  git@github.com:guysyml/stagemail.git && \
curl -o scala-$SCALA_VERSION.tgz http://downloads.typesafe.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.tgz && \
  tar -xf scala-$SCALA_VERSION.tgz && \
  rm scala-$SCALA_VERSION.tgz && \
  echo >> /root/.bashrc && \
  echo 'export PATH=~/scala-$SCALA_VERSION/bin:$PATH' >> /root/.bashrc

# Install sbt
RUN \
  curl -L -o sbt-$SBT_VERSION.deb https://dl.bintray.com/sbt/debian/sbt-$SBT_VERSION.deb && \
  dpkg -i sbt-$SBT_VERSION.deb && \
  rm sbt-$SBT_VERSION.deb && \
  apt-get update && \
  apt-get install sbt && \
  cd /opt/stagemail/StageMail && sbt compile && sbt clean
	
# Generate Configuration file from Environment Variables
RUN echo '[program:play]\ndirectory=/opt/stagemail/StageMail\ncommand=sbt clean start -Dapplication.secret=abcdefghifdgdgf' > /etc/supervisor/conf.d/play.conf && \
	echo '#!/bin/bash\nsed -i "s/POSTGRES_URL/$POSTGRES_URL/;s/POSTGRES_USER_NAME/$POSTGRES_USER_NAME/;s/$POSTGRES_PASSWORD/$$POSTGRES_PASSWORD/;s/COUCHBASE_HOST_1/$COUCHBASE_HOST_1/;s/COUCHBASE_HOST_2/$COUCHBASE_HOST_2/;s/COUCHBASE_HOST_3/$COUCHBASE_HOST_3/;s/COUCHBASE_BUCKET_NAME/$COUCHBASE_BUCKET_NAME/;s/COUCHBASE_BUCKET_PASSWORD/$COUCHBASE_BUCKET_PASSWORD/;" /opt/stagemail/StageMail/conf/config.properties\nsupervisord -n -c /etc/supervisor/supervisord.conf' > /start && \
	chmod +x /start

CMD /start
CMD [ "/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf" ]

