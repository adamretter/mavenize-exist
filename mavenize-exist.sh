#!/bin/bash

set -e
#set -x	# enable for debugging

SRC_DIR=/Users/aretter/code/exist-for-release

DEST_DIR="`pwd`/target"


##
# Creates a Module
#
# @param $1 The module name
##
function create_module {
	local MODULE_NAME=$1

	echo "Creating module: $MODULE_NAME..."
	local MODULE_DIR="${DEST_DIR}/${MODULE_NAME}"
	mkdir -p "${MODULE_DIR}"

	copy_pom $MODULE_NAME
}

##
# Copies a file to a pom file
#
# @param $1 The module name
##
function copy_pom {
	local MODULE_NAME=$1

	local MODULE_DIR="${DEST_DIR}/${MODULE_NAME}"
	cp "${1}.pom" "${MODULE_DIR}/pom.xml"
	echo "Created POM ${MODULE_NAME}/pom.xml"
}

##
# Copies the src/main/java files for a module
#
# @param $1 The module name
# @param $2 An array of package names which contain the sources
##
function copy_main_java {
	local MODULE_NAME=$1
	local MAIN_JAVA_SOURCES=("${!2}")
	local MODULE_DIR="${DEST_DIR}/${1}"

	local MAIN_JAVA_FIND_ARGS=('-name' '*.java')
	copy_main "${MODULE_NAME}" MAIN_JAVA_SOURCES[@] 'src/main/java' MAIN_JAVA_FIND_ARGS[@]
}

##
# Copies the src/main/resources for a module
#
# @param $1 The module name
# @param $2 An array of package names which contain the resources
##
function copy_main_resources {
        local MODULE_NAME=$1
	local MAIN_RESOURCES_SOURCES=("${!2}")
        local MODULE_DIR="${DEST_DIR}/${1}"

	local MAIN_RESOURCES_FIND_ARGS=('-not' '-name' '*.java')
	copy_main "${MODULE_NAME}" MAIN_RESOURCES_SOURCES[@] 'src/main/resources' MAIN_RESOURCES_FIND_ARGS[@]
}

##
# Function for copying maven module files
#
# @param $1 The module name
# @param $2 An array of package names which contain the files
# @param $3 The maven module directory, e.g. 'src/main/java'
# @param $4 An array of arguments to the find command to locate specific file types.
##
function copy_main {
        local MODULE_NAME=$1
	local SOURCES=("${!2}")
	local MVN_SRC_DIR=$3
	local FIND_ARGS=("${!4}")
        local MODULE_DIR="${DEST_DIR}/${1}"

	echo "Copying module files: ${MODULE_NAME}/${MVN_SRC_DIR}..."

        for src in "${SOURCES[@]}"
        do  
                local d="${SRC_DIR}/src/${src}"
                local FILES=(`find $d -maxdepth 1 -type f "${FIND_ARGS[@]}"`)
                for file in "${FILES[@]}"
                do  
                        local destfile="${MODULE_DIR}/${MVN_SRC_DIR}${file##$SRC_DIR/src}"
                        local destdir=$(dirname "${destfile}")

                        if [ ! -d "${destdir}" ]
                        then
                                mkdir -p "${destdir}"
                        fi  
                        cp -v "${file}" "${destfile}"
                done
        done
}

##
# Creates a .gitignore file suitable for a Java Maven project
#
##
function create_mvn_java_git_ignore {

	echo -e ""
	echo "Creating .gitignore"

	cat > "${DEST_DIR}/.gitignore" <<EOL
# Maven Output
target/

# IntelliJ IDEA
.idea/
*.iml

# Eclipse
.classpath
.project
.settings

# NetBeans
nbproject/
EOL
}

##
# Mavenizes an eXist-db Module
#
# @param $1 The module name
##
function mavenize_module {
	local MODULE_NAME=$1
	local MODULE_PACKAGES=("${!2}")

	echo "Mavenizing module: ${MODULE_NAME}..."

	#create_std_project_layout $MODULE_NAME
	create_module $MODULE_NAME
	copy_main_java $MODULE_NAME MODULE_PACKAGES[@]
	copy_main_resources $MODULE_NAME MODULE_PACKAGES[@]
}

##
# Extracts package names from a Jar file
#
# @param $1 the name of the jar file in $SRC_DIR
#
# @out $PKGS will hold an array of unique package names
##
function extract_package_names {
	local JAR_FILENAME=$1

	echo -e ""
	echo "Extracting package names from ${JAR_FILENAME}..."

	IFS=$'\r\n' GLOBIGNORE='*' command eval  'JAR_LIST=($(jar tvf $SRC_DIR/$JAR_FILENAME))'

	PKGS=()
	for jarentry in "${JAR_LIST[@]}"
	do
        	local JAR_ENTRY_FILE=`echo ${jarentry} | cut -d' ' -f8`

        	# only packages for which we actually have class files
        	if [[ $JAR_ENTRY_FILE == *".class"* ]]
        	then
                	JAR_ENTRY_FILE=$(dirname "${JAR_ENTRY_FILE}")
                	PKGS+=("$JAR_ENTRY_FILE")    
        	fi  
	done

	# reduce to unique pkgs
	PKGS=($(echo "${PKGS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
}


echo -e ""
echo "Reading eXist-db from ${SRC_DIR}..."
echo "Writing Mavenized eXist-db to ${DEST_DIR}..."
echo -e ""


### Copy infrastructure poms
mkdir -p target
cp -v exist-maven-modules.pom "${DEST_DIR}/pom.xml"
mkdir -p "${DEST_DIR}/exist-parent"
cp -v exist-parent.pom "${DEST_DIR}/exist-parent/pom.xml"

###  Mavenize each eXist-db Module

extract_package_names 'start.jar'
EXIST_START_PKGS=( "${PKGS[@]}" )
mavenize_module exist-start EXIST_START_PKGS[@]

extract_package_names 'exist.jar'
EXIST_CORE_PKGS=("${PKGS[@]}")
mavenize_module exist-core EXIST_CORE_PKGS[@]

create_mvn_java_git_ignore 

echo -e ""
echo "Completed OK :-)"
