FROM centurylink/ruby-base:2.1.2

MAINTAINER CenturyLink Labs <clt-labs-futuretech@centurylink.com>

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y graphviz
RUN gem install docker-api sinatra

ADD . /usr/src/app/
WORKDIR /usr/src/app
RUN chmod +x image-graph.sh

CMD [""]
ENTRYPOINT ["./image-graph.sh"]
