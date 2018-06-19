#!/usr/bin/env bash

set -e
#set -x	# enable for debugging

SRC_DIR=/Users/aretter/code/exist-for-release

OUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEST_DIR="${OUR_DIR}/target"


##
# Creates a Maven Module
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
function copy_main_java_pkgs {
	local MODULE_NAME=$1
	local MAIN_JAVA_SOURCES=("${!2}")

	local MAIN_JAVA_FIND_ARGS=('-name' '*.java')
	copy_mvn_pkgs "${MODULE_NAME}" "${SRC_DIR}/src" MAIN_JAVA_SOURCES[@] 'src/main/java' MAIN_JAVA_FIND_ARGS[@]
}

##
# Copies the src/main/resources for a module
#
# @param $1 The module name
# @param $2 An array of package names which contain the resources
##
function copy_main_resources_pkgs {
        local MODULE_NAME=$1
	local MAIN_RESOURCES_SOURCES=("${!2}")

	local MAIN_RESOURCES_FIND_ARGS=('-not' '-name' '*.java')
	copy_mvn_pkgs "${MODULE_NAME}" "${SRC_DIR}/src" MAIN_RESOURCES_SOURCES[@] 'src/main/resources' MAIN_RESOURCES_FIND_ARGS[@]
}

##
# Copies the src/test/java files for a module
#
# @param $1 The module name
# @param $2 An array of package names which contain the sources
##
function copy_test_java_pkgs {
        local MODULE_NAME=$1
        local TEST_JAVA_SOURCES=("${!2}")

        local TEST_JAVA_FIND_ARGS=('-name' '*.java')
        copy_mvn_pkgs "${MODULE_NAME}" "${SRC_DIR}/test/src" TEST_JAVA_SOURCES[@] 'src/test/java' TEST_JAVA_FIND_ARGS[@]
}

##
# Copies the src/test/resources for a module
#
# @param $1 The module name
# @param $2 An array of package names which contain the resources
##
function copy_test_resources_pkgs {
        local MODULE_NAME=$1
        local TEST_RESOURCES_SOURCES=("${!2}")

        local TEST_RESOURCES_FIND_ARGS=('-not' '-name' '*.java')
        copy_mvn_pkgs "${MODULE_NAME}" "${SRC_DIR}/test/src" TEST_RESOURCES_SOURCES[@] 'src/test/resources' TEST_RESOURCES_FIND_ARGS[@]
}

##
# Function for copying maven module files
#
# @param $1 The module name
# @param $2 the absolute path to the source base
# @param $3 An array of package names which contain the files
# @param $4 The maven module directory, e.g. 'src/main/java'
# @param $5 An array of arguments to the find command to locate specific file types.
##
function copy_mvn_pkgs {
        local MODULE_NAME=$1
	local SOURCE_BASE=$2
	local SOURCES=("${!3}")
	local MVN_SRC_DIR=$4
	local FIND_ARGS=("${!5}")
        local MODULE_DIR="${DEST_DIR}/${MODULE_NAME}"

	echo "Copying module files: ${MODULE_NAME}/${MVN_SRC_DIR}..."

        for src in "${SOURCES[@]}"
        do  
                local SD="${SOURCE_BASE}/${src}"
		if [ -d "$SD" ]
		then
                	local FILES=(`find $SD -maxdepth 1 -type f "${FIND_ARGS[@]}"`)
                	for file in "${FILES[@]}"
                	do  
                        	local DEST_FILE="${MODULE_DIR}/${MVN_SRC_DIR}${file##$SOURCE_BASE}"
                        	local DEST_DIR=$(dirname "${DEST_FILE}")

                        	if [ ! -d "${DEST_DIR}" ]
                        	then
                                	mkdir -p "${DEST_DIR}"
                        	fi  
                        	cp -v "${file}" "${DEST_FILE}"
                	done
		fi
        done
}

##
# Copies the files for src/main/java
#
# @param $1 The module name
# @param $2 An array of absolute paths to source files
##
function copy_main_java_files {
	local MODULE_NAME=$1
	local MAIN_JAVA_SOURCES=("${!2}")

	copy_mvn_files "${MODULE_NAME}" MAIN_JAVA_SOURCES[@] 'src/main/java'
}

##
# Copies the files for src/main/resources
#
# @param $1 The module name
# @param $2 An array of absolute paths to source files
##
function copy_main_resources_files {
        local MODULE_NAME=$1
        local MAIN_RESOURCES_SOURCES=("${!2}")

        copy_mvn_files "${MODULE_NAME}" MAIN_RESOURCES_SOURCES[@] 'src/main/resources'
}

##
# Copies the files for src/test/java
#
# @param $1 The module name
# @param $2 An array of absolute paths to source files
##
function copy_test_java_files {
        local MODULE_NAME=$1
        local TEST_JAVA_SOURCES=("${!2}")

        copy_mvn_files "${MODULE_NAME}" TEST_JAVA_SOURCES[@] 'src/test/java'
}

##
# Copies the files for src/test/resources
#
# @param $1 The module name
# @param $2 An array of absolute paths to source files
##
function copy_test_resources_files {
        local MODULE_NAME=$1
        local TEST_RESOURCES_SOURCES=("${!2}")

        copy_mvn_files "${MODULE_NAME}" TEST_RESOURCES_SOURCES[@] 'src/test/resources'
}


function copy_mvn_files {
	local MODULE_NAME=$1
        local SOURCES=("${!2}")
        local MVN_SRC_DIR=$3
        local MODULE_DIR="${DEST_DIR}/${MODULE_NAME}"

	echo "Copying module files: ${MODULE_NAME}/${MVN_SRC_DIR}..."

	for src in "${SOURCES[@]}"
	do
		local REL_SOURCE_FILE=$(echo "$src" | sed -E "s|.*/src/(.*)|\1|g")
		local DEST_FILE="${MODULE_DIR}/${MVN_SRC_DIR}/${REL_SOURCE_FILE}"
		local DEST_DIR=$(dirname "${DEST_FILE}")

		if [ ! -d "${DEST_DIR}" ]
		then
			mkdir -p "${DEST_DIR}"
		fi
		cp -v "${src}" "${DEST_FILE}"
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
# Mavenizes an eXist-db Module from package names
#
# @param $1 The module name
##
function mavenize_module_pkgs {
	local MODULE_NAME=$1
	local MODULE_PACKAGES=("${!2}")

	echo "Mavenizing module: ${MODULE_NAME}..."

	create_module $MODULE_NAME
	copy_main_java_pkgs $MODULE_NAME MODULE_PACKAGES[@]
	copy_main_resources_pkgs $MODULE_NAME MODULE_PACKAGES[@]
	copy_test_java_pkgs $MODULE_NAME MODULE_PACKAGES[@]
	copy_test_resources_pkgs $MODULE_NAME MODULE_PACKAGES[@]
}

###
# Mavenizes an eXist-db Module from file names
#
# @param $1 The module name
# @param $2 An array of absolute paths from the source to be used as the src/main/java files.
# @param $3 An array of absolute paths from the source to be used as the src/main/resources files.
# @param $4 An array of absolute paths from the source to be used as the src/test/java files.
# @param $5 An array of absolute paths from the source to be used as the src/test/resources files.
##
function mavenize_module_files {
	local MODULE_NAME=$1
	local MODULE_MAIN_JAVA_FILES=("${!2}")
	local MODULE_MAIN_RESOURCES_FILES=("${!3}")
	local MODULE_TEST_JAVA_FILES=("${!4}")
	local MODULE_TEST_RESOURCES_FILES=("${!5}")

	echo "Mavenizing module: ${MODULE_NAME}..."

	create_module $MODULE_NAME
	copy_main_java_files $MODULE_NAME MODULE_MAIN_JAVA_FILES[@]
	copy_main_resources_files $MODULE_NAME MODULE_MAIN_RESOURCES_FILES[@]
        copy_test_java_files $MODULE_NAME MODULE_TEST_JAVA_FILES[@]
        copy_test_resources_files $MODULE_NAME MODULE_TEST_RESOURCES_FILES[@]
}

##
# Extracts package names from a Jar file
#
# @param $1 the name of the jar file in $SRC_DIR
#
# @out $PKGS will hold an array of unique package names
##
function extract_jar_package_names {
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

##
# Extracts file names from a Jar file
#
# @param $1 the name of the jar file in $SRC_DIR
#
# @out $FILES will hold an array of relative file paths
##
function extract_jar_file_names {
        local JAR_FILENAME=$1

        echo -e ""
        echo "Extracting file names from ${JAR_FILENAME}..."

        IFS=$'\r\n' GLOBIGNORE='*' command eval  'JAR_LIST=($(jar tvf $SRC_DIR/$JAR_FILENAME))'

        FILES=()
        for jarentry in "${JAR_LIST[@]}"
        do  
                local JAR_ENTRY_FILE=`echo ${jarentry} | cut -d' ' -f8`
                local len=${#JAR_ENTRY_FILE}

                # only files, not folders
                if [ "${JAR_ENTRY_FILE:$len-1:1}" != "/" ]
                then
                        FILES+=("$JAR_ENTRY_FILE")
                fi  
        done
}

##
# Filters an array of strings
#
# @param $1 An array of strings
# @param $2 A regular expression to match
#
# @out $FILTERED_ARRAY will contain the filtered array
##
function filter_array {
        local ARY=("${!1}")
        local PATTERN=$2

        FILTERED_ARRAY=()
        for elem in "${ARY[@]}"
        do
                if [[ "${elem}" =~ $PATTERN ]]
                then
                        FILTERED_ARRAY+=("$elem")
                fi
        done
}

##
# Filters an array of strings to remove subclasses
#
# @param $1 An array of strings
#
# @out $FILTERED_ARRAY will contain the filtered array
##
function filter_notsubclass_array {
        local ARY=("${!1}")

        FILTERED_ARRAY=()
        for elem in "${ARY[@]}"
        do  
                if [[ ! "${elem}" == *[\$]* ]]
                then
                        FILTERED_ARRAY+=("$elem")
                fi  
        done
}

##
# Performs a replace on each string in an array of strings
#
# @param $1 An array of strings
# @param $2 A Sed extended regular expression
#
# @out $REPLACES_ARRAY will contain the new array with replacements
##
function replace_array {
        local ARY=("${!1}")
        local EXPR=$2

        REPLACED_ARRAY=()
        for elem in "${ARY[@]}"
        do
		local NEW_ELEM=$(echo "${elem}" | sed -E "${EXPR}")
                REPLACED_ARRAY+=("$NEW_ELEM")
        done
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

#extract_jar_package_names 'start.jar'
#EXIST_START_PKGS=( "${PKGS[@]}" )
#mavenize_module_pkgs exist-start EXIST_START_PKGS[@]

## Note there is a cicular dependency between the source files in start.jar, exist.jar and exist-optional.jar, so for now we just put both into exist-core
extract_jar_package_names 'start.jar'
EXIST_CORE_PKGS=("${PKGS[@]}")
extract_jar_package_names 'exist.jar'
EXIST_CORE_PKGS+=("${PKGS[@]}")
extract_jar_package_names 'exist-optional.jar'
EXIST_CORE_PKGS+=("${PKGS[@]}")
mavenize_module_pkgs 'exist-core' EXIST_CORE_PKGS[@]
# additional test classes needed
ADDITIONAL_TEST_JAVA_PKGS=(
	'org/exist/xmldb/concurrent'
	'org/exist/xmldb/concurrent/action'
	'org/exist/util/sorters'
)
copy_test_java_pkgs 'exist-core' ADDITIONAL_TEST_JAVA_PKGS[@]
# copy resources needed for running tests
ADDITIONAL_TEST_RESOURCE_PKGS=(
	'ant'
	'org/exist/config'
	'org/exist/config/mapping'
	'org/exist/dom/persistent'
	'org/exist/performance'
	'org/exist/util'
	'org/exist/xmldb'
	'org/exist/xquery'
	'org/exist/xupdate'
	'org/exist/xupdate/input'
	'org/exist/xupdate/modifications'
	'org/exist/xupdate/results'
	'xquery'
	'xquery/maps'
	'xquery/util'
	'xquery/xinclude'
	'xquery/xmlcalabash'
	'xquery/xproc'
	'xquery/xquery3'
)
copy_test_resources_pkgs 'exist-core' ADDITIONAL_TEST_RESOURCE_PKGS[@]
cp -v "${OUR_DIR}/exist-core.test.conf.xml" "${DEST_DIR}/exist-core/src/test/resources/conf.xml"
cp -v "${SRC_DIR}/LICENSE" ${DEST_DIR}/exist-core/src/test/resources/"

# jetty webapp stuff
# TODO(AR) should be split into a separate Maven module
mkdir -p "${DEST_DIR}/exist-core/src/test/resources/tools/jetty"
cp -v -r "${SRC_DIR}/tools/jetty/etc" "${DEST_DIR}/exist-core/src/test/resources/tools/jetty"
cp -v -r "${SRC_DIR}/tools/jetty/webapps" "${DEST_DIR}/exist-core/src/test/resources/tools/jetty"
mkdir -v "${DEST_DIR}/exist-core/src/test/resources/webapp"
find "${SRC_DIR}/webapp" -maxdepth 1 -type f -exec cp -v {} "${DEST_DIR}/exist-core/src/test/resources/webapp"
cp -v -r "${SRC_DIR}/webapp/resources" "${DEST_DIR}/exist-core/src/test/resources/webapp"
mkdir -v "${DEST_DIR}/exist-core/src/test/resources/webapp/WEB-INF"
find "${SRC_DIR}/webapp/WEB-INF" -maxdepth 1 -type f -exec cp -v {} "${DEST_DIR}/exist-core/src/test/resources/webapp/WEB-INF"
cp -v -r "${SRC_DIR}/webapp/WEB-INF/entities" "${DEST_DIR}/exist-core/src/test/resources/webapp/WEB-INF"

mkdir -p "${DEST_DIR}/exist-core/src/test/resources/samples"
cp -v "${SRC_DIR}/samples/biblio.rdf" "${DEST_DIR}/exist-core/src/test/resources/samples"
cp -v -r "${SRC_DIR}/samples/shakespeare" "${DEST_DIR}/exist-core/src/test/resources/samples"
cp -v -r "${SRC_DIR}/samples/validation" "${DEST_DIR}/exist-core/src/test/resources/samples"
cp -v -r "${SRC_DIR}/samples/xinclude" "${DEST_DIR}/exist-core/src/test/resources/samples"
cp -v -r "${SRC_DIR}/samples/xupdate" "${DEST_DIR}/exist-core/src/test/resources/samples"
rm "${DEST_DIR}/exist-core/src/test/java/org/exist/xquery/functions/util/CounterTest.java"              # TODO(AR)temp, we need to move this to the counter module
# Antlr2 parsers should be generated as part of the build
mkdir -p "${DEST_DIR}/exist-core/src/main/antlr/org/exist/xquery/parser"
mv -v ${DEST_DIR}/exist-core/src/main/resources/org/exist/xquery/parser/*.g "${DEST_DIR}/exist-core/src/main/antlr/org/exist/xquery/parser"
find "${DEST_DIR}/exist-core/src/main/java/org/exist/xquery/parser" -type f -maxdepth 1 -not -name \*AST.java -exec rm {} \;
rm -rf "${DEST_DIR}/exist-core/src/main/resources/org/exist/xquery/parser"
mkdir -p "${DEST_DIR}/exist-core/src/main/antlr/org/exist/xquery/xqdoc/parser"
mv -v ${DEST_DIR}/exist-core/src/main/resources/org/exist/xquery/xqdoc/parser/*.g "${DEST_DIR}/exist-core/src/main/antlr/org/exist/xquery/xqdoc/parser"
rm -rf "${DEST_DIR}/exist-core/src/main/java/org/exist/xquery/xqdoc/parser" "${DEST_DIR}/exist-core/src/main/resources/org/exist/xquery/xqdoc/parser"

extract_jar_file_names 'exist-testkit.jar'
EXIST_TESTKIT_FILES=("${FILES[@]}")
filter_array EXIST_TESTKIT_FILES[@] '\.class$'
EXIST_TESTKIT_FILES=("${FILTERED_ARRAY[@]}")
filter_notsubclass_array EXIST_TESTKIT_FILES[@]
EXIST_TESTKIT_FILES=("${FILTERED_ARRAY[@]}")
BASE_SRC_PATH="${SRC_DIR}/test/src/"
replace_array EXIST_TESTKIT_FILES[@] "s|(.*)\.class\$|${BASE_SRC_PATH}\1.java|g"
EXIST_TESTKIT_FILES=("${REPLACED_ARRAY[@]}")
# mavenize_module_files 'exist-testkit' EXIST_TESTKIT_FILES[@]  ## Note there is a circular dependency between the source files in exist-testkit.jar and the tests for exist.jar, so for now we also put these into exist-core
copy_test_java_files 'exist-core' EXIST_TESTKIT_FILES[@]

create_mvn_java_git_ignore 

echo -e ""
echo "Completed OK :-)"
