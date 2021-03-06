# Elasticsearch, Logstash, Kibana (ELK) Docker image documentation

This web page documents how to use the [sebp/elk](https://hub.docker.com/r/sebp/elk/) Docker image, which provides a convenient centralised log server and log management web interface, by packaging [Elasticsearch](http://www.elasticsearch.org/), [Logstash](http://logstash.net/), and [Kibana](http://www.elasticsearch.org/overview/kibana/), collectively known as ELK.

### Contents ###

- [Installation](#installation)
	- [Pulling specific version combinations](#specific-version-combinations)
- [Usage](#usage)
	- [Running the container using Docker Compose](#running-with-docker-compose)
	- [Running the container using Kitematic](#running-with-kitematic)
	- [Creating a dummy log entry](#creating-dummy-log-entry)
	- [Starting services selectively](#selective-services)
	- [Overriding start-up variables](#overriding-variables)
- [Forwarding logs](#forwarding-logs)
	- [Forwarding logs with Filebeat](#forwarding-logs-filebeat)
	- [Forwarding logs with Logstash forwarder](#forwarding-logs-logstash-forwarder)
	- [Linking a Docker container to the ELK container](#linking-containers)
- [Building the image](#building-image)
- [Tweaking the image](#tweaking-image)
	- [Updating Logstash's configuration](#updating-logstash-configuration)
	- [Installing Elasticsearch plugins](#installing-elasticsearch-plugins)
	- [Installing Logstash plugins](#installing-logstash-plugins)
	- [Installing Kibana plugins](#installing-kibana-plugins)
- [Persisting log data](#persisting-log-data)
- [Setting up an Elasticsearch cluster](#elasticsearch-cluster)
	- [Running Elasticsearch nodes on different hosts](#elasticsearch-cluster-different-hosts)
	- [Running Elasticsearch nodes on a single host](#elasticsearch-cluster-single-host)
	- [Optimising your Elasticsearch cluster](#optimising-elasticsearch-cluster)
- [Security considerations](#security-considerations)
	- [Notes on certificates](#certificates)
	- [Disabling SSL/TLS](#disabling-ssl-tls)
- [Troubleshooting](#troubleshooting)
- [Reporting issues](#reporting-issues)
- [Breaking changes](#breaking-changes)
- [References](#references)
- [About](#about)

## Installation <a name="installation"></a>

Install [Docker](https://docker.com/), either using a native package (Linux) or wrapped in a virtual machine (Windows, OS X – e.g. using [Boot2Docker](http://boot2docker.io/) or [Vagrant](https://www.vagrantup.com/)).

To pull this image from the [Docker registry](https://hub.docker.com/r/sebp/elk/), open a shell prompt and enter:

	$ sudo docker pull sebp/elk

**Note** – This image has been built automatically from the source files in the [source Git repository on GitHub](https://github.com/spujadas/elk-docker). If you want to build the image yourself, see the [Building the image](#building-image) section.

### Pulling specific version combinations <a name="specific-version-combinations"></a> 

Specific version combinations of Elasticsearch, Logstash and Kibana can be pulled by using tags.

For instance, the image containing Elasticsearch 1.7.3, Logstash 1.5.5, and Kibana 4.1.2 (which is the last image using the Elasticsearch 1.x and Logstash 1.x branches) bears the tag `E1L1K4`, and can therefore be pulled using `sudo docker pull sebp/elk:E1L1K4`.

The available tags are listed on [Docker Hub's sebp/elk image page](https://hub.docker.com/r/sebp/elk/) or GitHub repository page.

By default, if not tag is indicated (or if using the tag `latest`), the latest version of the image will be pulled.

## Usage <a name="usage"></a>

Run a container from the image with the following command:

	$ sudo docker run -p 5601:5601 -p 9200:9200 -p 5044:5044 -p 5000:5000 -p 5001:5001 -it --name elk sebp/elk

**Note** – The whole ELK stack will be started. See the *[Starting services selectively](#selective-services)* section to selectively start part of the stack.

This command publishes the following ports, which are needed for proper operation of the ELK stack:

- 5601 (Kibana web interface).
- 9200 (Elasticsearch JSON interface).
- 5044 (Logstash Beats interface, receives logs from Beats such as Filebeat – see the *[Forwarding logs with Filebeat](#forwarding-logs-filebeat)* section).
- 5000 (Logstash Lumberjack interface, receives logs from Logstash forwarders – see the *[Forwarding logs with Logstash forwarder](#forwarding-logs-logstash-forwarder)* section).

**Note** – The image also exposes Elasticsearch's transport interface on port 9300. Use the `-p 9300:9300` option with the `docker` command above to publish it. This transport interface is notably used by [Elasticsearch's Java client API](https://www.elastic.co/guide/en/elasticsearch/client/java-api/current/index.html).

The figure below shows how the pieces fit together.

![](http://i.imgur.com/wDertsM.png)

Access Kibana's web interface by browsing to `http://<your-host>:5601`, where `<your-host>` is the hostname or IP address of the host Docker is running on (see note), e.g. `localhost` if running a local native version of Docker, or the IP address of the virtual machine if running a VM-hosted version of Docker (see note).

**Note** – To configure and/or find out the IP address of a VM-hosted Docker installation, see [https://docs.docker.com/installation/windows/](https://docs.docker.com/installation/windows/) (Windows) and [https://docs.docker.com/installation/mac/](https://docs.docker.com/installation/mac/) (OS X) for guidance if using Boot2Docker. If you're using [Vagrant](https://www.vagrantup.com/), you'll need to set up port forwarding (see [https://docs.vagrantup.com/v2/networking/forwarded_ports.html](https://docs.vagrantup.com/v2/networking/forwarded_ports.html).

You can stop the container with `^C`, and start it again with `sudo docker start elk`.

As from Kibana version 4.0.0, you won't be able to see anything (not even an empty dashboard) until something has been logged (see the *[Creating a dummy log entry](#creating-dummy-log-entry)* sub-section below on how to test your set-up, and the *[Forwarding logs](#forwarding-logs)* section on how to forward logs from regular applications).

When filling in the index pattern in Kibana (default is `logstash-*`), note that in this image, Logstash uses an output plugin that is configured to work with Beat-originating input (e.g. as produced by Filebeat, see [Forwarding logs with Filebeat](#forwarding-logs-filebeat)) and that logs will be indexed with a `<beatname>-` prefix (e.g. `filebeat-` when using Filebeat).

### Running the container using Docker Compose <a name="running-with-docker-compose"></a>

If you're using [Docker Compose](https://docs.docker.com/compose/) to manage your Docker services (and if not you really should as it will make your life much easier!), then you can create an entry for the ELK Docker image by adding the following lines to your `docker-compose.yml` file:

	elk:
	  image: sebp/elk
	  ports:
	    - "514:514"
	    - "5601:5601"
	    - "9200:9200"
	    - "5044:5044"
	    - "5000:5000"
	    - "5001:5001"

You can then start the ELK container like this:

	$ sudo docker-compose up elk

### Running the container using Kitematic <a name="running-with-kitematic"></a>

Windows and OS X users may prefer to use a simple graphical user interface to run the container, as provided by [Kitematic](https://kitematic.com/), which is included in the [Docker Toolbox](https://www.docker.com/products/docker-toolbox).

After starting Kitematic and creating a new container from the sebp/elk image, click on the *Settings* tab, and then on the *Ports* sub-tab to see the list of the ports exposed by the container (under *DOCKER PORT*) and the list of IP addresses and ports they are published on and accessible from on your machine (under *MAC IP:PORT*).

You may for instance see that Kibana's web interface (which is exposed as port 5601 by the container) is published at an address like 192.168.99.100:32770, which you can now go to in your browser.

**Note** – The rest of this document assumes that the exposed and published ports share the same number (e.g. will use `http://<your-host>:5601/` to refer to Kibana's web interface), so when using Kitematic you need to make sure that you replace both the hostname with the IP address *and* the exposed port with the published port listed by Kitematic (e.g. `http://192.168.99.100:32770` in the previous example).

### Creating a dummy log entry <a name="creating-dummy-log-entry"></a>

If you haven't got any logs yet and want to manually create a dummy log entry for test purposes (for instance to see the dashboard), first start the container as usual (`sudo docker run ...` or `docker-compose up ...`).

In another terminal window, find out the name of the container running ELK, which is displayed in the last column of the output of the `sudo docker ps` command.

	$ sudo docker ps
	CONTAINER ID        IMAGE                  ...   NAMES
	86aea21cab85        elkdocker_elk:latest   ...   elkdocker_elk_1

Open a shell prompt in the container and type (replacing `<container-name>` with the name of the container, e.g. `elkdocker_elk_1` in the example above):

	$ sudo docker exec -it <container-name> /bin/bash

At the prompt, enter:

_(since Logstash 2.0.0)_

	# /opt/logstash/bin/logstash -e 'input { stdin { } } output { elasticsearch { hosts => ["localhost"] } }'

_(before Logstash 2.0.0)_

	# /opt/logstash/bin/logstash -e 'input { stdin { } } output { elasticsearch { host => localhost } }'

Wait for Logstash to start (as indicated by the message `Logstash startup completed`), then type some dummy text followed by Enter to create a log entry:

	this is a dummy entry

**Note** – You can create as many entries as you want. Use `^C` to go back to the bash prompt.

If you browse to `http://<your-host>:9200/_search?pretty` (e.g. [http://localhost:9200/_search?pretty](http://localhost:9200/_search?pretty) for a local native instance of Docker) you'll see that Elasticsearch has indexed the entry:

	{
	  ...
	  "hits": {
	    ...
	    "hits": [ {
	      "_index": "logstash-...",
	      "_type": "logs",
	      ...
	      "_source": { "message": "this is a dummy entry", "@version": "1", "@timestamp": ... }
	    } ]
	  }
	}

You can now browse to Kibana's web interface at `http://<your-host>:5601` (e.g. [http://localhost:5601](http://localhost:5601) for a local native instance of Docker).

Make sure that the drop-down "Time-field name" field is pre-populated with the value `@timestamp`, then click on "Create", and you're good to go.

### Starting services selectively <a name="selective-services"></a>

By default, when starting a container, all three of the ELK services (Elasticsearch, Logstash, Kibana) are started.

The following environment variables may be used to selectively start a subset of the services:

- `ELASTICSEARCH_START`: if set and set to anything other than `1`, then Elasticsearch will not be started.
 
- `LOGSTASH_START`: if set and set to anything other than `1`, then Logstash will not be started.

- `KIBANA_START`: if set and set to anything other than `1`, then Kibana will not be started.

For example, the following command starts Elasticsearch only:

	$ sudo docker run -p 5601:5601 -p 9200:9200 -p 5044:5044 -p 5000:5000 -it \
		-e LOGSTASH_START=0 -e KIBANA_START=0 --name elk sebp/elk

Note that if the container is to be started with Elasticsearch _disabled_, then:

- If Logstash is enabled, then you need to make sure that the configuration file for Logstash's Elasticsearch output plugin (`/etc/logstash/conf.d/30-output.conf`) points to a host belonging to the Elasticsearch cluster rather than `localhost` (which is the default in the ELK image, since by default Elasticsearch and Logstash run together), e.g.:
	
		output {
		  elasticsearch { hosts => ["elk-master.example.com"] }
		}

- Similarly, if Kibana is enabled, then Kibana's `kibana.yml` configuration file must first be updated to make the `elasticsearch.url` setting (default value: `"http://localhost:9200"`) point to a running instance of Elasticsearch.

### Overriding start-up variables <a name="overriding-variables"></a>

The following environment variables can be used to override the defaults used to start up the services:

- `ES_HEAP_SIZE`: Elasticsearch heap size (default is 256MB min, 1G max)

	Specifying a heap size – e.g. `2g` – will set both the min and max to the provided value. To set the min and max values separately, see the `ES_JAVA_OPTS` below. 

- `ES_JAVA_OPTS`: additional Java options for Elasticsearch (default: `""`)
 
	For instance, to set the min and max heap size to 512MB and 2G, set this environment variable to `-Xms512m -Xmx2g`.

- `LS_HEAP_SIZE`: Logstash heap size (default: `"500m"`)

- `LS_OPTS`: Logstash options (default: `"--auto-reload"` in images with tags `es231_l231_k450` and `es232_l232_k450`, `""` in `latest`; see [Breaking changes](#breaking-changes))
 
As an illustration, the following command starts the stack, running Elasticsarch with a 2GB heap size, Logstash with a 1GB heap size and Logstash's configuration auto-reload disabled:

	$ sudo docker run -p 5601:5601 -p 9200:9200 -p 5044:5044 -p 5000:5000 -it \
		-e ES_HEAP_SIZE="2g" -e LS_HEAP_SIZE="1g" -e LS_OPTS="--no-auto-reload" \
		--name elk sebp/elk

## Forwarding logs <a name="forwarding-logs"></a>

Forwarding logs from a host relies on a forwarding agent that collects logs (e.g. from log files, from the syslog daemon) and sends them to our instance of Logstash.

The forwarding agent that was originally used with Logstash was Logstash forwarder, but with the introduction of the [Beats platform](https://www.elastic.co/products/beats) it will be phased out in favour of Filebeat, which should now be the preferred option. The two approaches are described hereafter.

### Forwarding logs with Filebeat <a name="forwarding-logs-filebeat"></a>

Install [Filebeat](https://www.elastic.co/products/beats/filebeat) on the host you want to collect and forward logs from (see the *[References](#references)* section for links to detailed instructions).

#### Example Filebeat set-up and configuration

**Note** – The `nginx-filebeat` subdirectory of the [source Git repository on GitHub](https://github.com/spujadas/elk-docker) contains a sample `Dockerfile` which enables you to create a Docker image that implements the steps below.

Here is a sample `/etc/filebeat/filebeat.yml` configuration file for Filebeat, that forwards syslog and authentication logs, as well as [nginx](http://nginx.org/) logs.

	output:
	  logstash:
	    enabled: true
	    hosts:
	      - elk:5044
	    tls:
		  certificate_authorities:
      	    - /etc/pki/tls/certs/logstash-beats.crt
	    timeout: 15
	
	filebeat:
	  prospectors:
	    -
	      paths:
	        - /var/log/syslog
	        - /var/log/auth.log
	      document_type: syslog
	    -
	      paths:
	        - "/var/log/nginx/*.log"
	      document_type: nginx-access

In the sample configuration file, make sure that you replace `elk` in `elk:5044` with the hostname or IP address of the ELK-serving host.

You'll also need to copy the `logstash-beats.crt` file (which contains the certificate authority's certificate – or server certificate as the certificate is self-signed – for Logstash's Beats input plugin; see [Security considerations](#security-considerations) for more information on certificates) from the [source repository of the ELK image](https://github.com/spujadas/elk-docker) to `/etc/pki/tls/certs/logstash-beats.crt`.

**Note** – The ELK image includes configuration items (`/etc/logstash/conf.d/11-nginx.conf` and `/opt/logstash/patterns/nginx`) to parse nginx access logs, as forwarded by the Filebeat instance above.

Before starting Filebeat for the first time, run this command (replace `elk` with the appropriate hostname) to load the default index template in Elasticsearch:

		curl -XPUT 'http://elk:9200/_template/filebeat?pretty' -d@/etc/filebeat/filebeat.template.json

Start Filebeat:

		sudo /etc/init.d/filebeat start

#### Note on processing multiline log entries

In order to process multiline log entries (e.g. stack traces) as a single event using Filebeat, you may want to consider [Filebeat's multiline option](https://www.elastic.co/blog/beats-1-1-0-and-winlogbeat-released), which was introduced in Beats 1.1.0, as a handy alternative to altering Logstash's configuration files to use [Logstash's multiline codec](https://www.elastic.co/guide/en/logstash/current/plugins-codecs-multiline.html).

### Forwarding logs with Logstash forwarder <a name="forwarding-logs-logstash-forwarder"></a>

**Note** – This approach is deprecated: [using Filebeat](#forwarding-logs-filebeat) is now the preferred way to forward logs.

Install [Logstash forwarder](https://github.com/elasticsearch/logstash-forwarder) on the host you want to collect and forward logs from (see the *[References](#references)* section for links to detailed instructions).

Here is a sample configuration file for Logstash forwarder, that forwards syslog and authentication logs, as well as [nginx](http://nginx.org/) logs.

	{
	  "network": {
	    "servers": [ "elk:5000" ],
	    "timeout": 15,
	    "ssl ca": "/etc/pki/tls/certs/logstash-forwarder.crt"
	  },
	  "files": [
	    {
	      "paths": [
	        "/var/log/syslog",
	        "/var/log/auth.log"
	       ],
	      "fields": { "type": "syslog" }
	    },
	    {
	      "paths": [
	        "/var/log/nginx/access.log"
	       ],
	      "fields": { "type": "nginx-access" }
	    }
	   ]
	}

By default (see `/etc/init.d/logstash-forwarder` if you need to tweak anything):

- The Logstash forwarder configuration file must be located in `/etc/logstash-forwarder`.
- The Logstash forwarder needs a syslog daemon (e.g. rsyslogd, syslog-ng) to be running.

In the sample configuration file, make sure that you replace `elk` in `elk:5000` with the hostname or IP address of the ELK-serving host.

You'll also need to copy the `logstash-forwarder.crt` file (which contains the certificate authority's certificate – or server certificate as the certificate is self-signed – for Logstash's Lumberjack input plugin; see [Security considerations](#security-considerations) for more information on certificates) from the ELK image to `/etc/pki/tls/certs/logstash-forwarder.crt`.

Lastly, you'll need to alter Logstash's Elasticsearch output plugin configuration (in `30-output.conf`) to remove the reference to the dynamic field `%{[@metadata][beat]}` in the `index` configuration option, as this field implies that a Beat is being used to forward logs. A minimal configuration file such as the following would work fine:

	output {
	  elasticsearch { hosts => ["localhost"] }
	  stdout { codec => rubydebug }
	}

As a more complex example if you want Elasticsearch to process logs from both Beats (such as Filebeat) and Logstash forwarders, you could use an `if` condition to separate the incoming logs and use differentiated indices, e.g.: 

	output {
	  if [@metadata][beat] {
	    elasticsearch {
	      hosts => ["localhost"]
	      sniffing => true
	      manage_template => false
	      index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}" 
	      document_type => "%{[@metadata][type]}" 
	    } 
	  } else {
	    elasticsearch { 
	      hosts => ["localhost"]
	      index => "other" 
	      document_type => "stuff" 
	    }
	  }
	  stdout { 
	    codec => rubydebug 
	  }
	} 
 
**Note** – The ELK image includes configuration items (`/etc/logstash/conf.d/11-nginx.conf` and `/opt/logstash/patterns/nginx`) to parse nginx access logs, as forwarded by the Logstash forwarder instance above.

### Linking a Docker container to the ELK container <a name="linking-containers"></a>

If you want to forward logs from a Docker container to the ELK container, then you need to link the two containers.

**Note** – The log-emitting Docker container must have a Logstash forwarder agent running in it for this to work.

First of all, give the ELK container a name (e.g. `elk`) using the `--name` option:

	$ sudo docker run -p 5601:5601 -p 9200:9200 -p 5044:5044 -p 5000:5000 -it --name elk sebp/elk

Then start the log-emitting container with the `--link` option (replacing `your/image` with the name of the Logstash-forwarder-enabled image you're forwarding logs from):

	$ sudo docker run -p 80:80 -it --link elk:elk your/image

From the perspective of the log emitting container, the ELK container is now known as `elk`, which is the hostname to be used in the `logstash-forwarder` configuration file.

With Compose here's what example entries for a (locally built log-generating) container and an ELK container might look like in the `docker-compose.yml` file.

	yourapp:
	  image: your/image
	  ports:
	    - "80:80"
	  links:
	    - elk

	elk:
	  image: sebp/elk
	  ports:
	    - "5601:5601"
	    - "9200:9200"
	    - "5044:5044"
	    - "5000:5000"

## Building the image <a name="building-image"></a>

To build the Docker image from the source files, first clone the [Git repository](https://github.com/spujadas/elk-docker), go to the root of the cloned directory (i.e. the directory that contains `Dockerfile`), and:

- If you're using the vanilla `docker` command then run `sudo docker build -t <repository-name> .`, where `<repository-name>` is the repository name to be applied to the image, which you can then use to run the image with the `docker run` command.

- If you're using Compose then run `sudo docker-compose build elk`, which uses the `docker-compose.yml` file from the source repository to build the image. You can then run the built image with `sudo docker-compose up`.

## Tweaking the image <a name="tweaking-image"></a>

There are several approaches to tweaking the image:

- Use the image as a base image and extend it, adding files (e.g. configuration files to process logs sent by log-producing applications, plugins for Elasticsearch) and overwriting files (e.g. configuration files, certificate and private key files) as required. See Docker's [Dockerfile Reference page](https://docs.docker.com/reference/builder/) for more information on writing a `Dockerfile`.

- Replace existing files by bind-mounting local files to files in the container. See Docker's [Manage data in containers](https://docs.docker.com/engine/userguide/containers/dockervolumes/) page for more information on volumes in general and bind-mounting in particular.

- Fork the source Git repository and hack away.

The next few subsections present some typical use cases.

### Updating Logstash's configuration <a name="updating-logstash-configuration"></a>

The image contains several configuration files for Logstash (e.g. `01-lumberjack-input.conf`, `02-beats-input.conf`), all located in `/etc/logstash/conf.d`.

To modify an existing configuration file, you can bind-mount a local configuration file to a configuration file within the container at runtime. For instance, if you want to replace the image's `30-output.conf` Logstash configuration file with your local file `/path/to/your-30-output.conf`, then you would add the following `-v` option to your `docker` command line:

	$ sudo docker run ... \
		-v /path/to/your-30-output.conf:/etc/logstash/conf.d/30-output.conf \
		...

To create your own image with updated or additional configuration files, you can create a `Dockerfile` that extends the original image, with contents such as the following:

	FROM seb/elk
	
	# overwrite existing file
	ADD /path/to/your-30-output.conf /etc/logstash/conf.d/30-output.conf
	
	# add new file
	ADD /path/to/new-12-some-filter.conf /etc/logstash/conf.d/12-some-filter.conf

Then build the extended image using the `docker build` syntax. 

### Installing Elasticsearch plugins <a name="installing-elasticsearch-plugins"></a>

Elasticsearch's home directory in the image is `/usr/share/elasticsearch`, its [plugin management script](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-plugins.html) (`plugin`) resides in the `bin` subdirectory, and plugins are installed in `plugins`.

Elasticsearch runs as the user `elasticsearch`. To avoid issues with permissions, it is therefore recommended to install Elasticsearch plugins as `elasticsearch`, using the `gosu` command (see below for an example, and references for further details).  

A `Dockerfile` like the following will extend the base image and install Elastic HQ, a management and monitoring plugin for Elasticsearch, using `plugin`.

	FROM sebp/elk

	ENV ES_HOME /usr/share/elasticsearch
	WORKDIR ${ES_HOME}

	RUN gosu elasticsearch bin/plugin install royrusso/elasticsearch-HQ

You can now build the new image (see the *[Building the image](#building-image)* section above) and run the container in the same way as you did with the base image. The Elastic HQ interface will be accessible at `http://<your-host>:9200/_plugin/hq/` (e.g. [http://localhost:9200/_plugin/hq/](http://localhost:9200/_plugin/hq/) for a local native instance of Docker).

### Installing Logstash plugins <a name="installing-logstash-plugins"></a>

The name of Logstash's home directory in the image is stored in the `LOGSTASH_HOME` environment variable (which is set to `/opt/logstash` in the base image). Logstash's plugin management script (`plugin`) is located in the `bin` subdirectory.

Logstash runs as the user `logstash`. To avoid issues with permissions, it is therefore recommended to install Kibana plugins as `logstash`, using the `gosu` command (see below for an example, and references for further details).  

The following `Dockerfile` can be used to extend the base image and install the [RSS input plugin](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-rss.html):

	FROM sebp/elk

	WORKDIR ${LOGSTASH_HOME}
	RUN gosu logstash bin/logstash-plugin install logstash-input-rss

See the *[Building the image](#building-image)* section above for instructions on building the new image. You can then run a container based on this image using the same command line as the one in the *[Usage](#usage)* section.

### Installing Kibana plugins <a name="installing-kibana-plugins"></a>

The name of Kibana's home directory in the image is stored in the `KIBANA_HOME` environment variable (which is set to `/opt/kibana` in the base image). Kibana's plugin management script (`plugin`) is located in the `bin` subdirectory, and plugins are installed in `installedPlugins`.

Kibana runs as the user `kibana`. To avoid issues with permissions, it is therefore recommended to install Kibana plugins as `kibana`, using the `gosu` command (see below for an example, and references for further details).  

The following `Dockerfile` can be used to extend the base image and install the latest version of the [Sense plugin](https://www.elastic.co/guide/en/sense/current/index.html), a handy console for interacting with the REST API of Elasticsearch:

	FROM sebp/elk

	WORKDIR ${KIBANA_HOME}
	RUN gosu kibana bin/kibana plugin -i elastic/sense

See the *[Building the image](#building-image)* section above for instructions on building the new image. You can then run a container based on this image using the same command line as the one in the *[Usage](#usage)* section. The Sense interface will be accessible at `http://<your-host>:5601/apss/sense` (e.g. [http://localhost:5601/app/sense](http://localhost:5601/app/sense) for a local native instance of Docker).

## Persisting log data <a name="persisting-log-data"></a>

In order to keep log data across container restarts, this image mounts `/var/lib/elasticsearch` — which is the directory that Elasticsearch stores its data in — as a volume.

You may however want to use a dedicated data volume to persist this log data, for instance to facilitate back-up and restore operations.

One way to do this is to mount a Docker named volume using `docker`'s `-v` option, as in:

	$ sudo docker run -p 5601:5601 -p 9200:9200  -p 5044:5044 -p 5000:5000 \
		-v elk-data:/var/lib/elasticsearch --name elk sebp/elk

This command mounts the named volume `elk-data` to `/var/lib/elasticsearch` (and automatically creates the volume if it doesn't exist; you could also pre-create it manually using `docker volume create elk-data`).

**Note** – By design, Docker never deletes a volume automatically (e.g. when no longer used by any container). Whilst this avoids accidental data loss, it also means that things can become messy if you're not managing your volumes properly (i.e. using the `-v` option when removing containers with `docker rm` to also delete the volumes... bearing in mind that the actual volume won't be deleted as long as at least one container is still referencing it, even if it's not running). You can keep track of existing volumes using `docker volume ls`.

See Docker's page on [Managing Data in Containers](https://docs.docker.com/engine/userguide/containers/dockervolumes/) and Container42's [Docker In-depth: Volumes](http://container42.com/2014/11/03/docker-indepth-volumes/) page for more information on managing data volumes.

## Setting up an Elasticsearch cluster <a name="elasticsearch-cluster"></a>

The ELK image can be used to run an Elasticsearch cluster, either on [separate hosts](#elasticsearch-cluster-different-hosts) or (mainly for test purposes) on a [single host](#elasticsearch-cluster-single-host), as described below.

For more (non-Docker-specific) information on setting up an Elasticsearch cluster, see the [Life Inside a Cluster section](https://www.elastic.co/guide/en/elasticsearch/guide/current/distributed-cluster.html) section of the Elasticsearch definitive guide.

### Running Elasticsearch nodes on different hosts <a name="elasticsearch-cluster-different-hosts"></a>

To run nodes on different hosts, you'll need to update Elasticsearch's `/etc/elasticsearch/elasticsearch.yml` file in the Docker image to configure the [zen discovery module](http://www.elastic.co/guide/en/elasticsearch/reference/current/modules-discovery.html) as needed for the nodes to find each other. Specifically, you need to add a `discovery.zen.ping.unicast.hosts` directive to point to the IP addresses or hostnames of hosts that should be polled to perform discovery when Elasticsearch is started on each node.

As an example, start an ELK container as usual on one host, which will act as the first master. Let's assume that the host is called *elk-master.example.com*.

Have a look at the cluster's health:

	$ curl http://elk-master.example.com:9200/_cluster/health?pretty
	{
	  "cluster_name" : "elasticsearch",
	  "status" : "yellow",
	  "timed_out" : false,
	  "number_of_nodes" : 1,
	  "number_of_data_nodes" : 1,
	  "active_primary_shards" : 6,
	  "active_shards" : 6,
	  "relocating_shards" : 0,
	  "initializing_shards" : 0,
	  "unassigned_shards" : 6,
	  "delayed_unassigned_shards" : 6,
	  "number_of_pending_tasks" : 0,
	  "number_of_in_flight_fetch" : 0,
	  "task_max_waiting_in_queue_millis" : 0,
	  "active_shards_percent_as_number" : 50.0
	}

This shows that only one node is up at the moment, and the `yellow` status indicates that all primary shards are active, but not all replica shards are active.

Then, on another host, create a file named `elasticsearch-slave.yml` (let's say it's in `/home/elk`), with the following contents:

	network.host: 0.0.0.0
	discovery.zen.ping.unicast.hosts: ["elk-master.example.com"]

You can now start an ELK container that uses this configuration file, using the following command (which mounts the configuration files on the host into the container):

	$ sudo docker run -it --rm=true -p 9200:9200 \
	  -v /home/elk/elasticsearch-slave.yml:/etc/elasticsearch/elasticsearch.yml \
	  sebp/elk

Once Elasticsearch is up, displaying the cluster's health on the original host now shows:

	$ curl http://elk-master.example.com:9200/_cluster/health?pretty
	{
	  "cluster_name" : "elasticsearch",
	  "status" : "green",
	  "timed_out" : false,
	  "number_of_nodes" : 2,
	  "number_of_data_nodes" : 2,
	  "active_primary_shards" : 6,
	  "active_shards" : 12,
	  "relocating_shards" : 0,
	  "initializing_shards" : 0,
	  "unassigned_shards" : 0,
	  "delayed_unassigned_shards" : 0,
	  "number_of_pending_tasks" : 0,
	  "number_of_in_flight_fetch" : 0,
	  "task_max_waiting_in_queue_millis" : 0,
	  "active_shards_percent_as_number" : 100.0
	}

### Running Elasticsearch nodes on a single host <a name="elasticsearch-cluster-single-host"></a>

Setting up Elasticsearch nodes to run on a single host is similar to running the nodes on different hosts, but the containers need to be linked in order for the nodes to discover each other.

Start the first node using the usual `docker` command on the host:

	$ sudo docker run -p 5601:5601 -p 9200:9200 -p 5044:5044 -p 5000:5000 -it --name elk sebp/elk

Now, create a basic `elasticsearch-slave.yml` file containing the following lines:

	network.host: 0.0.0.0
	discovery.zen.ping.unicast.hosts: ["elk"]

Start a node using the following command:

	$ sudo docker run -it --rm=true \
	  -v /var/sandbox/elk-docker/elasticsearch-slave.yml:/etc/elasticsearch/elasticsearch.yml \
	  --link elk:elk --name elk-slave sebp/elk

Note that Elasticsearch's port is not published to the host's port 9200, as it was already published by the initial ELK container.

### Optimising your Elasticsearch cluster <a name="optimising-elasticsearch-cluster"></a>

You can use the ELK image as is to run an Elasticsearch cluster, especially if you're just testing, but to optimise your set-up, you may want to have:

- One node running the complete ELK stack, using the ELK image as is.

- Several nodes running _only_ Elasticsearch (see *[Starting services selectively](#selective-services)*).

An even more optimal way to distribute Elasticsearch, Logstash and Kibana across several nodes or hosts would be to run only the required services on the appropriate nodes or hosts (e.g. Elasticsearch on several hosts, Logstash on a dedicated host, and Kibana on another dedicated host).

## Security considerations <a name="security-considerations"></a>

As it stands this image is meant for local test use, and as such hasn't been secured: access to the ELK services is unrestricted, and default authentication server certificates and private keys for the Logstash input plugins are bundled with the image.

To harden this image, at the very least you would want to:

- Restrict the access to the ELK services to authorised hosts/networks only, as described in e.g. [Elasticsearch Scripting and Security](http://www.elasticsearch.org/blog/scripting-security/) and [Elastic Security: Deploying Logstash, ElasticSearch, Kibana "securely" on the Internet](http://blog.eslimasec.com/2014/05/elastic-security-deploying-logstash.html).
- Password-protect the access to Kibana and Elasticsearch (see [SSL And Password Protection for Kibana](http://technosophos.com/2014/03/19/ssl-password-protection-for-kibana.html)).
- Generate a new self-signed authentication certificate for the Logstash input plugins (see [Notes on certificates](#certificates)) or (better) get a proper certificate from a commercial provider (known as a certificate authority), and keep the private key private.

If on the other hand you want to disable certificate-based server authentication (e.g. in a demo environment), see [Disabling SSL/TLS](#disabling-ssl-tls).

### Notes on certificates <a name="certificates"></a>

Dummy server authentication certificates (`/etc/pki/tls/certs/logstash-*.crt`) and private keys (`/etc/pki/tls/private/logstash-*.key`) are included in the image.

The certificates are assigned to hostname `*`, which means that they will work if you are using a single-part (i.e. no dots) domain name to reference the server from your client.

**Example** – In your client (e.g. Filebeat), sending logs to hostname `elk` will work, `elk.mydomain.com` will not (will produce an error along the lines of `x509: certificate is valid for *, not elk.mydomain.com`), neither will an IP address such as 192.168.0.1 (expect `x509: cannot validate certificate for 192.168.0.1 because it doesn't contain any IP SANs`).

If you cannot use a single-part domain name, then you could consider:

- Issuing a self-signed certificate with the right hostname using a variant of the commands given below.

- Issuing a certificate with the [IP address of the ELK stack in the subject alternative name field](https://github.com/elastic/logstash-forwarder/issues/221#issuecomment-48390920), even though this is bad practice in general as IP addresses are likely to change.

- Adding a single-part hostname (e.g. `elk`) to your client's `/etc/hosts` file.    

The following commands will generate a private key and a 10-year self-signed certificate issued to a server with hostname `elk` for the Beats input plugin:

	$ cd /etc/pki/tls
	$ sudo openssl req -x509 -batch -nodes -subj "/CN=elk/" \
		-days 3650 -newkey rsa:2048 \
		-keyout private/logstash-beats.key -out certs/logstash-beats.crt

As another example, when running a non-predefined number of containers concurrently in a cluster with hostnames _directly_ under the `.mydomain.com` domain (e.g. `elk1.mydomain.com`, `elk2.mydomain.com`, etc.; _not_ `elk1.subdomain.mydomain.com`, `elk2.othersubdomain.mydomain.com` etc.), you could create a certificate assigned to the wildcard hostname `*.example.com` by using the following command (all other parameters are identical to the ones in the previous example).   

	$ cd /etc/pki/tls
	$ sudo openssl req -x509 -batch -nodes -subj "/CN=*.example.com/" \
		-days 3650 -newkey rsa:2048 \
		-keyout private/logstash-beats.key -out certs/logstash-beats.crt

To make Logstash use the generated certificate to authenticate to a Beats client, extend the ELK image to overwrite (e.g. using the `Dockerfile` directive `ADD`):

- the certificate file (`logstash-beats.crt`) with `/etc/pki/tls/certs/logstash-beats.crt`.
- the private key file (`logstash-beats.key`) with `/etc/pki/tls/private/logstash-beats.key`,

Additionally, remember to configure your Beats client to trust the newly created certificate using the `certificate_authorities` directive, as presented in [Forwarding logs with Filebeat](#forwarding-logs-filebeat).

### Disabling SSL/TLS <a name="disabling-ssl-tls"></a>

Certificate-based server authentication requires log-producing clients to trust the server's root certificate authority's certificate, which can be an unnecessary hassle in zero-criticality environments (e.g. demo environments, sandboxes).

To disable certificate-based server authentication, remove all `ssl` and `ssl`-prefixed directives (e.g. `ssl_certificate`, `ssl_key`) in Logstash's input plugin configuration files.

For instance, with the default configuration files in the image, replace the contents of `02-beats-input.conf` (for Beats emitters) with:

	input {
	  beats {
	    port => 5044
	  }
	}

Similarly, for Logstash forwarders, replace the contents of `01-lumberjack-input.conf` with:

	input {
	  lumberjack {
	    port => 5000
	    type => "logs"
	  }
	}

## Troubleshooting <a name="troubleshooting"></a>

Here are a few pointers to help you troubleshoot your containerised ELK.

If your log-emitting client doesn't seem to be able to reach Logstash (or Elasticsearch, depending on where your client is meant to send logs to), make sure that:

- You started the container with the right ports open (e.g. 5044 for Beats).

- The ports are reachable from the client machine (e.g. make sure the appropriate rules have been set up on your firewalls to authorise outbound flows from your client and inbound flows on your ELK-hosting machine).

- Your client is configured to connect to Logstash using TLS (or SSL) and that it trusts Logstash's self-signed certificate (or certificate authority if you replaced the default certificate with a proper certificate – see [Security considerations](#security-considerations)).   

If this still seems to fail, then you should have a look at:

- Your log-emitting client's logs.

- ELK's logs, by `docker exec`'ing into the running container (see [Creating a dummy log entry](#creating-dummy-log-entry)) and checking Logstash's logs (located in `/var/log/logstash`), Elasticsearch's logs (in `/var/log/elasticsearch`), and Kibana's logs (in `/var/log/kibana`).

	Note that ELK's logs are rotated daily and are deleted after a week, using logrotate. You can change this behaviour by overwriting the `elasticsearch`, `logstash` and `kibana` files in `/etc/logrotate.d`.  

For non-Docker-related issues with Elasticsearch, Kibana, and Elasticsearch, make sure you have a look at the [Elastic forums](https://discuss.elastic.co/).

## Reporting issues <a name="reporting-issues"></a>

You can report issues with this image using [GitHub's issue tracker](https://github.com/spujadas/elk-docker/issues) (please avoid raising issues as comments on Docker Hub, if only for the fact that the notification system is broken at the time of writing so there's a fair chance that I won't see it for a while).

Bearing in mind that the first thing I'll need to do is reproduce your issue, please provide as much relevant information (e.g. logs, configuration files, what you were expecting and what you got instead, any troubleshooting steps that you took, what _is_ working) as possible for me to do that.

[Pull requests](https://github.com/spujadas/elk-docker/pulls) are also welcome if you have found an issue and can solve it.

## Breaking changes <a name="breaking changes"></a>

Here is the list of breaking changes that may cause images built on later versions of the ELK image (rather tha

- **Version 5** (advance warning)

	*Applies to tags: to be announced.*

	Breaking changes are to be expected in the upcoming version 5 of [Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/master/breaking-changes.html), [Logstash](https://www.elastic.co/guide/en/logstash/master/breaking-changes.html), and [Kibana](https://www.elastic.co/guide/en/kibana/master/releasenotes.html).

- **Logstash forwarder** (advance warning)

	*Applies to tags: same as for version 5 (see above).*

	The use of Logstash forwarder is deprecated, its Logstash input plugin configuration will soon be removed, and port 5000 will no longer be exposed.

- **Java 8**

	*Applies to tags: `es234_l234_k452` and later.*

	This image initially used Oracle JDK 7, which is [no longer updated by Oracle](http://www.oracle.com/technetwork/java/javase/eol-135779.html), and no longer available as a Ubuntu package.

	As from tag `es234_l234_k452`, the image uses Oracle JDK 8. This may have unintended side effects on plugins that rely on Java.

- **Logstash configuration auto-reload**

	*Applies to tags: `es231_l231_k450`, `es232_l232_k450`.*

	Logstash's configuration auto-reload option was introduced in Logstash 2.3 and enabled in the images with tags `es231_l231_k450` and `es232_l232_k450`.

	As this feature created a resource leak prior to Logstash 2.3.3 (see [https://github.com/elastic/logstash/issues/5235](https://github.com/elastic/logstash/issues/5235)), the `--auto-reload` option was removed as from the `es233_l232_k451`-tagged image (see [https://github.com/spujadas/elk-docker/issues/41](https://github.com/spujadas/elk-docker/issues/41)).

	Users of images with tags `es231_l231_k450` and `es232_l232_k450` are strongly recommended:

	- To either override Logstash's options to disable the auto-reload feature by setting the `LS_OPTS` environment to `--no-auto-reload` if this feature is not needed.
	- Or to use a later version of the image (from `es234_l234_k452` onwards) and pass `--auto-reload` to `LS_OPTS` if the feature is needed.

## References <a name="references"></a>

- [How To Install Elasticsearch, Logstash, and Kibana 4 on Ubuntu 14.04](https://www.digitalocean.com/community/tutorials/how-to-install-elasticsearch-logstash-and-kibana-4-on-ubuntu-14-04)
- [The Docker Book](http://www.dockerbook.com/)
- [The Logstash Book](http://www.logstashbook.com/)
- [Elastic's reference documentation](https://www.elastic.co/guide/index.html):
	- [Elasticsearch Reference](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
	- [Logstash Reference](https://www.elastic.co/guide/en/logstash/current/index.html)
	- [Kibana Reference](https://www.elastic.co/guide/en/kibana/current/index.html)
	- [Filebeat Reference](https://www.elastic.co/guide/en/beats/filebeat/current/index.html)
- [gosu, simple Go-based setuid+setgid+setgroups+exec](https://github.com/tianon/gosu), a convenient alternative to `USER` in Dockerfiles (see [Best practices for writing Dockerfiles](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#user))

## About <a name="about"></a>

Written by [Sébastien Pujadas](http://pujadas.net), released under the [Apache 2 license](http://www.apache.org/licenses/LICENSE-2.0).
