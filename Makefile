
#-----------------------|DOCUMENTATION|-----------------------#
# @descr: Makefile for project construction.
# @fonts: https://vsupalov.com/packer-ami/
#		  https://pt.wikibooks.org/wiki/Programar_em_C/Makefiles
# 		  https://blog.pantuza.com/tutoriais/como-funciona-o-makefile
#		  http://mindbending.org/pt/makefile-para-java
#		  https://www.embarcados.com.br/introducao-ao-makefile/	
#		  https://github.com/dyson/packer-qemu-coreos-container-linux/blob/master/Makefile	
# @example:
#       $ make plan compile validate build 
#   OR
#       $ make build-force  
#   OR
#       $ make clean  
#	OR
#       WARNING: When you change the RELEASE of CoreOS, you should also change the 
#       file in ".../container-linux-config/keys-to-underworld.yml" for (update: group: "alpha")
#		$ make plan compile build install-box \
#			   PACKER_ONLY="virtualbox-iso" \
#			   COREOS_RELEASE="alpha" \
#			   COREOS_VERSION="1688.0.0"
#   OR
#       $ make uninstall-box  
#-------------------------------------------------------------#

# DEFAULT VARIABLES - Structural
WORKING_DIRECTORY         ?= .
#WORKING_DIRECTORY        ?= `pwd`

# DEFAULT VARIABLES - Packer!!!
PACKER_TEMPLATE           ?= coreos-virtualbox-template.json
PACKER_VARIABLES		  ?= vars-global.json vars-coreos.json vars-virtualbox.json vars-custom.json
PACKER_ONLY               ?= virtualbox-iso

# DEFAULT VARIABLES - CoreOS!!!
# WARNING: When you change the RELEASE of CoreOS, you should also change the 
# file in ".../container-linux-config/keys-to-underworld.yml" for (update: group: "stable")
COREOS_RELEASE            ?= stable
COREOS_VERSION            ?= 1632.3.0

# DEFAULT VARIABLES - Ignition For CoreOS
IGNITION_SOURCE_FILE      ?= $(WORKING_DIRECTORY)/pre-provision/container-linux-config/keys-to-underworld.yml
IGNITION_COMPILATION_PATH ?= $(WORKING_DIRECTORY)/pre-provision/ignitions

# DEFAULT VARIABLES - Vagrant
VAGRANT_BOX_NAME          ?= lucifer/coreos-$(COREOS_RELEASE)
VAGRANT_BOX_PATH          ?= $(WORKING_DIRECTORY)/builds/coreos-$(COREOS_RELEASE)-$(COREOS_VERSION).box

# DEFAULT VARIABLES - Compile, validate and build image files for Project Packer.
BUILD_IMAGE_CMD           ?= $(WORKING_DIRECTORY)/build-image.sh


plan: 
	@echo "The default values to be used by this Makefile:";
	@echo "";
	@echo "    --> MAKECMDGOALS: make $(MAKECMDGOALS)";
	@echo "    --> WORKING_DIRECTORY: $(WORKING_DIRECTORY)";
	@echo "";
	@echo "    --> PACKER_TEMPLATE: $(PACKER_TEMPLATE)";
	@echo "    --> PACKER_VARIABLES: [$(PACKER_VARIABLES)]";
	@echo "    --> PACKER_ONLY: $(PACKER_ONLY)";
	@echo "";
	@echo "    --> COREOS_RELEASE: $(COREOS_RELEASE)";
	@echo "    --> COREOS_VERSION: $(COREOS_VERSION)";
	@echo "";
	@echo "    --> IGNITION_SOURCE_FILE: $(IGNITION_SOURCE_FILE)";
	@echo "    --> IGNITION_COMPILATION_PATH: $(IGNITION_COMPILATION_PATH)";
	@echo "";
	@echo "    --> VAGRANT_BOX_NAME: $(VAGRANT_BOX_NAME)";
	@echo "    --> VAGRANT_BOX_PATH: $(VAGRANT_BOX_PATH)";
	@echo "";
	@echo "    --> BUILD_IMAGE_CMD: $(BUILD_IMAGE_CMD)";
	@echo "";


compile: 
	@echo "Starting the compilation of the (IGNITION COREOS)..."; 
	@echo "--source file: $(IGNITION_SOURCE_FILE)"; 
	@echo "--compilation path: $(IGNITION_COMPILATION_PATH)"; 

	@bash $(BUILD_IMAGE_CMD) --action="compile" \
						     --source-file="$(IGNITION_SOURCE_FILE)" \
							 --compilation-path="$(IGNITION_COMPILATION_PATH)" \
							 --platforms="'vagrant-virtualbox' 'digitalocean' 'ec2' 'gce' 'azure' 'packet'";

	@echo "Complete compilation!";  


validate:
	@echo "Starting the validation of the template Packer..."; 
	@echo "--template file: $(WORKING_DIRECTORY)/templates/$(PACKER_TEMPLATE)"; 

	@bash $(BUILD_IMAGE_CMD) --action="validate" \
						     --template-file="$(WORKING_DIRECTORY)/templates/$(PACKER_TEMPLATE)" \
							 --variables="$(PACKER_VARIABLES)" \
							 --working-directory="$(WORKING_DIRECTORY)";

	@bash $(BUILD_IMAGE_CMD) --action="inspect" \
						     --template-file="$(WORKING_DIRECTORY)/templates/$(PACKER_TEMPLATE)";


build:
	@echo "Starting the BUILD of the template Packer..."; 
	@echo "--template file: $(WORKING_DIRECTORY)/templates/$(PACKER_TEMPLATE)";

	@bash $(BUILD_IMAGE_CMD) --action="build" \
						     --template-file="$(WORKING_DIRECTORY)/templates/$(PACKER_TEMPLATE)" \
							 --variables="$(PACKER_VARIABLES)" \
							 --packer-only="$(PACKER_ONLY)" \
							 --coreos-release="$(COREOS_RELEASE)" \
							 --coreos-version="$(COREOS_VERSION)" \
							 --working-directory="$(WORKING_DIRECTORY)";


build-force: clean compile validate build


clean:
	@echo "Initiating deletion of compilation files from the Project Packer...";
	@echo "--affected directory: $(WORKING_DIRECTORY)/builds";

	@rm -rf $(WORKING_DIRECTORY)/builds; sleep 2s;
	
	@echo "cleaning completed!"; 



# ----------------------------------------------------------------------
# THE CODES BELOW ARE INTENDED TO RUN THE TOOLS (Vagrant and VirtualBox)
# ----------------------------------------------------------------------

install-box: 
	@echo "Starting the installation of the Vagrant Box generated by Packer..."; 
	@echo "--box name: $(VAGRANT_BOX_NAME)"; 
	@echo "--box path: $(VAGRANT_BOX_PATH)"; 

	@vagrant box list;

	@echo "--> Vagrant Box Installation..."; 
	@bash $(BUILD_IMAGE_CMD) --action="install-box" \
							 --box-name="$(VAGRANT_BOX_NAME)" \
							 --box-path="$(VAGRANT_BOX_PATH)";

	@vagrant box list;

	@echo "Complete Vagrant Box installation!";  


publish-box: 
	@echo "Starting the publish of the Vagrant Box on Vagrant Cloud generated by Packer..."; 
	@echo "--box name: $(VAGRANT_BOX_NAME)"; 
	@echo "--box path: $(VAGRANT_BOX_PATH)"; 

	@echo "--> Vagrant Box Publish..."; 
	@bash $(BUILD_IMAGE_CMD) --action="publish-box" \
							 --box-path="$(VAGRANT_BOX_PATH)";

	@echo "Complete Vagrant Box publish!";  


uninstall-box: 
	@echo "Starting the uninstallation of the Vagrant Box generated by Packer..."; 
	@echo "--box be uninstall: $(VAGRANT_BOX_NAME)"; 

	@vagrant box list;
	@vagrant global-status;

	@echo "--> Vagrant Box Uninstallation..."; 
	@bash $(BUILD_IMAGE_CMD) --action="uninstall-box" \
							 --box-name="$(VAGRANT_BOX_NAME)";

	@vagrant box list;
	@vagrant global-status;

	@echo "Uninstalling the completed Vagrant Box!";

