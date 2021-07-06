FROM ubuntu:20.04

COPY ./test.sh /test.sh
RUN chmod a+x /test.sh

ENTRYPOINT ["/test.sh","-t","test"]
