# Riak
#
# Use the official Ubuntu Trusty base image
FROM ubuntu:trusty

# Install Riak repository before we do apt-get update
RUN apt-get install -q -y curl
# Install package sources for Riak KV. For Riak TS, change `riak` to `riak-ts`.
RUN curl -fsSL https://packagecloud.io/install/repositories/basho/riak/script.deb | sudo bash

# Install specific version of Riak, governed by `--build-arg RIAK_VERSION`
ARG RIAK_VERSION=2.0.7-1
RUN apt-get install -y riak=$RIAK_VERSION
# Generate Locale for UTF-8
RUN locale-gen en_US en_US.UTF-8

# Expose Riak Protocol Buffers and HTTP interfaces
EXPOSE 8087 8098

COPY start-riak.sh /usr/sbin/start-riak.sh
RUN chmod a+x /usr/sbin/start-riak.sh

CMD ["/usr/sbin/start-riak.sh"]