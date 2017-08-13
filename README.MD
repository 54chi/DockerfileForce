# jenkins-container-for-salesforce-builds

Jenkins image with Force.com Migrations tool.

## Features
Tools needed to make deployments to salesforce.com included in this image:

* [Jenkins](https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/)
* [Force.com Migrations Tool]( https://developer.salesforce.com/page/Force.com_Migration_Tool )
* [Ant](https://ant.apache.org/bindownload.cgi)
* [Maven 3](https://apache.osuosl.org/maven/maven-3/)
* [Open JDK8](http://www.oracle.com/technetwork/java/javase/downloads/index.html)

The image is created on top of Alpine and requires about ~400Mb

Other goodies included: `git, openssh-client, curl, unzip, tar`

## Jenkins Plugins

Jenkins needs plugins to be properly work. I've included the ones that I need under `plugins.txt` file, but your needs may be different.

If you want to create your own plugins file, you can export a list of plugins from an existing server by running this command:

```
curl -sSL "http://jenkins:jenkins@localhost:8080/pluginManager/api/xml?depth=1&xpath=/*/*/shortName|/*/*/version&wrapper=plugins" | perl -pe 's/.*?<shortName>([\w-]+).*?<version>([^<]+)()(<\/\w+>)+/\1 \2\n/g'|sed 's/ /:/' > plugins.txt
```

Then replace the plugins.txt accordingly.


## Getting Started

You will need to have [**docker**](https://www.docker.com/) installed in your machine and clone/download this repo.

Using the Dockerfile is as simple as having the docker daemon run one. The output after executing the script will be the ID of the new docker image.

Usage:

The first time, you will need to build a base image using the Dockerfile at current location

#### Example: sudo docker build -t [image_name] .

```sh
$ sudo docker build -t sf_jenkins .  
```

After the image is ready (it should take a few minutes), you are ready to spawn containers based on that image:

#### Example: docker run -p [port1]:[port2] [image_name]

This is the basic command to start sf_jenkins:

```sh
$ docker run -p 8080:8080 sf_jenkins
```

#### Example: docker run --name [container_name] -p [port1]:[port2] -v [volume1]:[volume2] [image_name]

This will create a container sf_jenkins_container and store all jenkins data and configuration from ~/Project/jenkinsProjects in your host PC and /var/jenkins_home in the container:

```sh
$ docker run --name sf_jenkins_container -p 8080:8080 -p 50000:50000 -v ~/Project/jenkinsProjects:/var/jenkins_home -d sf_jenkins
```

#### First time Jenkins user:

After the container is done, open a browser in your PC and point it to `http:\\localhost:8080` to finish setting it up (hint:  /var/jenkins_home/secrets/initialAdminPassword in the container maps to ~/Project/jenkinsProjects/secrets/initialAdminPassword in your PC)

On the next screen, if you don't want to install additional plugins, click on the "x" (the plugins were installed by the Dockerfile using `plugins.txt` file)

Please refer to jenkins official usage for a more complete explanation on the rest of jenkins matter: https://hub.docker.com/_/jenkins/

### The force's dataloader:

This is not officially supported (and hopefully will be replaced by salesforce DX in the future). You can download and compile the dataloader in the container:

1. Open a shell for the container (e.g. `docker exec -it <container_id> bash`)
1. Clone the [dataloader repo](https://github.com/forcedotcom/dataloader)
1. cd into the created folder and run `mvn clean package -DskipTests`
1. The dataloader.jar will be compiled and generated inside the "target" folder
1. Move the jar to the /var/jenkins_home folder for easy access
1. That's it. You can now use jenkins and java to call dataloader-40.0-uber.jar as part as your salesforce deployment process.

#### Generating the keyfile and encrypted password

From dataloader/target folder:

1. Generate the key (-g option):

  ```sh
  java -cp dataloader-40.0.0-uber.jar com.salesforce.dataloader.security.EncryptionUtil -g MySecretKey
  ```
  Copy the generated sequence (e.g. 2faaed6d2504fc0c) and paste it into a file you create (e.g. `key.txt`)

2. Generate the encrypted password (-e option):

  ```sh
  java -cp dataloader-40.0.0-uber.jar com.salesforce.dataloader.security.EncryptionUtil -e MyPassword "key.txt"
  ```
  Copy the generated sequence (e.g. 18623959594772bfea2e3caa8700f910) and store it somewhere safe. __NOTE__: If you are using a security token, add it to your password before the encryption (e.g. MyPasswordfoLRAgiaa9wtlSOviWv83JVf)
  
3. To validate the password with the key file, try this (-v option):

  ```sh
  java -cp dataloader-40.0.0-uber.jar com.salesforce.dataloader.security.EncryptionUtil -v 18623959594772bfea2e3caa8700f910 MyPassword "key.txt"
  ```
The encrypted password and the key files are needed to set the dataloader's config.properties file.

#### Example: Execute the process "Account" from process.xml

```sh
java -cp dataloader-40.0.0-uber.jar -Dsalesforce.config.dir=/var/jenkins_home/dataloader com.salesforce.dataloader.process.ProcessRunner process.name=Account
```

[More Info](http://www.jitendrazaa.com/blog/salesforce/using-dataloader-and-ant-to-backup-salesforce-data-on-ftp-server-video/)

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

You can find good example how to setup jenkins to deploy to salesforce in [Github wiki page](https://github.com/anyei/jenkins-to-salesforce/wiki)
