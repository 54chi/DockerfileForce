# jenkins-to-salesforce

Simple jenkins image with Force.com Migrations tool.

## Features
Tools needed to make deployments to salesforce.com included in this image:
* Force.com Migrations Tool ([official resources]( https://developer.salesforce.com/page/Force.com_Migration_Tool ))
* https://ant.apache.org/bindownload.cgi

## Plugins

If you want to create your own plugins file, you can export a list of plugins from an existing server by running this command:

```
curl -sSL "http://jenkins:jenkins@localhost:8080/pluginManager/api/xml?depth=1&xpath=/*/*/shortName|/*/*/version&wrapper=plugins" | perl -pe 's/.*?<shortName>([\w-]+).*?<version>([^<]+)()(<\/\w+>)+/\1 \2\n/g'|sed 's/ /:/' > plugins.txt
```

Then replace the plugins.txt accordingly.


## Usage

How to Use Dockerfiles

Using the Dockerfiles is as simple as having the docker daemon run one. The output after executing the script will be the ID of the new docker image.

Usage:

# Build an image using the Dockerfile at current location
# Example: sudo docker build -t [name] .
sudo docker build -t sf_jenkins .    

This is the basic command to start jenkins:
```sh
$ docker run -p 8080:8080 sf_jenkins
```
This will store all jenkins data and configuration in /var/jenkins_home. You can make that a persistent volume:

```sh
$ docker run --name docker_containername -p 8080:8080 -v /var/jenkins_home sf_jenkins
```

You can bind volume from host and container:
The jenkins user in container (jenkins user - uid 102, same as base jenkins image) must have access to /usr/back/jenkins:

```sh
$ docker run -p 8080:8080 -v /usr/back/jenkins:/var/jenkins_home sf_jenkins
```

You can do it all in one command too :
```sh
$ docker run --name jenkins-sfdc -p 8080:8080 -p 50000:50000 -v /usr/back/jenkins:/var/jenkins_home -d sf_jenkins
```

Please refer to jenkins official usage for a more complete explanation on the rest of jenkins matter: https://hub.docker.com/_/jenkins/

### Public key authentication with git
If you have a jenkins job setup with git plugin, the best way to authenticate against the server where the target repository lives is with a public key. Jenkins runs as jenkins user within the container, therefore you'll need jenkin's user public key.

Get inside the running container (we are assuming the containers name is jenkins-sfdc):
```sh
$ docker exec -it jenkins-sfdc /bin/bash
```
Then generate the rsa key pair :
```sh
$ ssh-keygen -t rsa
```
Follow the instructions, leaving everything in blank and just hitting enter key will be enough for the public and private key to get generated. Assuming you did so, the public key should be located in the following file /var/jenkins_home/.ssh/id_rsa.pub. You can use that key later to authenticate to github, bitbucket or any other servers accepting this type of authentication. For more information and additional example go to [Github wiki page](https://github.com/anyei/jenkins-to-salesforce/wiki).

### Documentation
You can find more about jenkins image in the official [docker repository](https://hub.docker.com/_/jenkins/).

You can find good example how to setup jenkins to deploy to saleforce in [Github wiki page](https://github.com/anyei/jenkins-to-salesforce/wiki)

### Issues
Let's keep this in [Github](https://github.com/anyei/jenkins-to-salesforce/issues).

### Contributing

You are invited to contribute, let's keep in touch in [Github](https://github.com/anyei/jenkins-to-salesforce)
