#!/bin/bash

set -e

SRC_DIR=/Users/aretter/code/exist-for-release

DEST_DIR="`pwd`/target"


##
# Creates a standard project layout for a module
#
# @param $1 The module name
##
function create_std_project_layout {
	MODULE_DIR="${DEST_DIR}/${1}"
	mkdir -p "${MODULE_DIR}/src/main/java" "${MODULE_DIR}/src/main/resources" "${MODULE_DIR}/src/test/java" "${MODULE_DIR}/src/test/resources"
}

function copy_pom {
	MODULE_DIR="${DEST_DIR}/${1}"
	cp "${1}.pom" "${MODULE_DIR}/pom.xml"
}

function copy_main_java {
	MODULE_NAME=$1
	SOURCES=$2
	MODULE_DIR="${DEST_DIR}/${1}"

	for src in "${SOURCES[@]}"
	do
		d="${SRC_DIR}/src/${src}"
		# find $d -name *.java -exec cp --verbose --parents {} $MODULE_DIR \;
		FILES=(`find $d -name \*.java`)
		for file in "${FILES[@]}"
		do
			destfile="${MODULE_DIR}/src/main/java${file##$SRC_DIR/src}"
			destdir=$(dirname "${destfile}")

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
	MODULE_NAME=$1
	MAIN_JAVA=$2
	MAIN_RESOURCES=$3
	TEST_JAVA=$4
	TEST_RESOURCES=$5

	create_std_project_layout $MODULE_NAME
	copy_pom $MODULE_NAME
	copy_main_java $MODULE_NAME $MAIN_JAVA
}

echo "Reading eXist-db from ${SRC_DIR}..."
echo "Writing Mavenized eXist-db to ${DEST_DIR}..."

mkdir -p target
cp -v exist-maven-modules.pom "${DEST_DIR}/pom.xml"
mkdir -p "${DEST_DIR}/exist-parent"
cp -v exist-parent.pom "${DEST_DIR}/exist-parent/pom.xml"

EXIST_START_MAIN_JAVA=("org/exist/start")

mavenize_module exist-start $EXIST_START_MAIN_JAVA
# mavenize_module exist-core

create_mvn_java_git_ignore 
