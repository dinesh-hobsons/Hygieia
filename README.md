Please refer to (https://github.com/capitalone/Hygieia) for original documentation.

###Changes 
The goal was to script manual tasks and workaround issues relevant to my use case.
* `setup_test_servers` sets up Sonar and Jenkins servers and loads data.
* `setup_hygieia` sets up Hygieia and collectors for Sonar and Jenkins. (Also creates mongo db user)
* Fixed syntax error in VersionOne property generator.
* Commented out support for multiple Jenkins Servers. Null server entries caused exceptions.
