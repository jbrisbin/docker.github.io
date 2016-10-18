---
description: Build a Docker image with Riak pre-installed
keywords:
- docker, example, package installation, networking,  riak
menu:
  main:
    parent: engine_dockerize
title: Dockerizing a Riak service
---

# Dockerizing a Riak service

The goal of this example is to show you how to build a Docker image with Riak pre-installed.

## Creating a Dockerfile

Create a new `Dockerfile`:

    $ vi Dockerfile

Next, define the parent image on which you want to base your own. We'll use [Ubuntu](https://hub.docker.com/_/ubuntu/) (tag: `trusty`), which is available on [Docker Hub](https://hub.docker.com):

    # Riak
    #
    # Use the official Ubuntu Trusty base image
    FROM ubuntu:trusty

We need to install `curl` to download the repository setup script from `packagecloud.io`:

    # Install Riak repository before we do apt-get update
    RUN apt-get install -q -y curl
    # Install package sources for Riak KV. For Riak TS, change `riak` to `riak-ts`.
    RUN curl -fsSL https://packagecloud.io/install/repositories/basho/riak/script.deb | sudo bash

Then we install Riak itself:

<!-- -->

    # Install specific version of Riak, governed by `--build-arg RIAK_VERSION`
    ARG RIAK_VERSION=2.0.7-1
    RUN apt-get install -y riak=$RIAK_VERSION
    # Generate Locale for UTF-8
    RUN locale-gen en_US en_US.UTF-8

We expose the Riak Protocol Buffers and HTTP interfaces on their default ports:

    # Expose Riak Protocol Buffers and HTTP interfaces
    EXPOSE 8087 8098

Now we need to create a special start script that will echo our IP address into the Riak configuration before starting the node. This will ensure the node can be connected to from other Docker containers using a valid IP address. There are some functions of Riak, like [Full Bucket Reads](http://basho.com/products/riak-kv/apache-spark-connector/), that need a valid IP address to be set as the node name so the client can connect back to it.

The following is based on [the official Riak Docker image script](https://github.com/basho-labs/riak-docker/blob/master/riak-cluster.sh#L27) that performs a similar function. 

Create a script file:

    $ vi start-riak.sh

Add some logic to use `ping` to discover our IP address and echo that information into `/etc/riak/riak.conf`:

    #!/bin/bash

    HOST=$(ping -c1 $HOSTNAME | awk '/^PING/ {print $3}' | sed 's/[()]//g')||'127.0.0.1'
    cat <<END >>/etc/riak/riak.conf
    nodename = riak@$HOST
    listener.protobuf.internal = $HOST:8087
    listener.http.internal = $HOST:8098
    END

    riak start
    riak-admin wait-for-service riak_kv

    tail -n 1024 -f /var/log/riak/console.log

Add this script to the Docker image:

    COPY start-riak.sh /usr/sbin/start-riak.sh
    RUN chmod a+x /usr/sbin/start-riak.sh

    CMD ["/usr/sbin/start-riak.sh"]

## Build the Docker image for Riak

Now you should be able to build a Docker image for Riak:

    $ docker build -t "<yourname>/riak-kv" .

## Run a single node Riak

Once the image is built, you can run a single node of Riak by using `docker run`:

    $ docker run -d --name=riak -p 8087:8087 -p 8098:8098 <yourname>/riak-kv
    ... monitor whie Riak starts ...
    $ docker logs riak

Eventually you should see the log line indicating the node has started:

    $ docker logs riak
    ... log output ...
    2016-10-18 15:54:46.841 [info] <0.7.0> Application riak_kv started on node 'riak@172.17.0.2'

## Next steps

Riak is a distributed database. Many production deployments consist of [at least five nodes](http://basho.com/why-your-riak-cluster-should-have-at-least-five-nodes/). See the [riak-docker](https://github.com/basho-labs/riak-docker) project for details on how to deploy a Riak cluster using Docker.
