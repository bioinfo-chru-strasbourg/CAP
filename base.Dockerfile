
##############################################################
# Dockerfile Version:   1.0
# Software:             CAP
# Software Version:     0.9.11b
# Software Website:     none
# Licence:              GNU Affero General Public License (AGPL)
# Description:          CAP
# Usage:                docker run [-v [DATA FOLDER]:/data] cap:version
##############################################################

##########
# README #
##########

# Config parameters
#    identify yum packages for installation
#    identify yum packages to remove
#
# Dependecies installation
#    identify tools dependences
#    config each tool
#    write installation procedure for each tools
#
# Tool
#    configure tool
#    write isntallation procedure for the tool
#    add link to current and root tool folder
#
# Workdir / Entrypoint / Cmd
#    configure workdir, endpoint and command
#    /!\ no variables in endpoint



########
# FROM #
########


FROM centos
MAINTAINER Antony Le Bechec <antony.lebechec@gmail.com>
LABEL Software="CAP" \
	Version="0.9.11b" \
	Website="none" \
	Description="CAP" \
	License="GNU Affero General Public License (AGPL)" \
	Usage="docker run [-v [DATA FOLDER]:/STARK/data] cap:version"



##############
# PARAMETERS #
##############

ENV TOOLS=/tools
ENV DATA=/data
ENV TOOL=/tool
ENV YUM_INSTALL="java-1.8.0 zlib-devel zlib zlib2-devel zlib2 bzip2-devel bzip2 lzma-devel lzma xz-devel xz ncurses-devel wget gcc gcc-c++ make perl perl-Switch perl-Digest-MD5 perl-Data-Dumper bc"
ENV YUM_REMOVE="zlib-devel bzip2-devel xz-devel ncurses-devel wget gcc gcc-c++"




###############
# YUM INSTALL #
###############

RUN yum install -y $YUM_INSTALL ;




################
# DEPENDENCIES #
################




##########
# HTSLIB #
##########

ENV TOOL_NAME=htslib
ENV TOOL_VERSION=1.8
ENV TARBALL_LOCATION=https://github.com/samtools/$TOOL_NAME/releases/download/$TOOL_VERSION/
ENV TARBALL=$TOOL_NAME-$TOOL_VERSION.tar.bz2
ENV DEST=$TOOLS/$TOOL_NAME/$TOOL_VERSION
ENV PATH=$TOOLS/$TOOL_NAME/$TOOL_VERSION/bin:$PATH

# INSTALL
RUN wget $TARBALL_LOCATION/$TARBALL ; \
    tar xf $TARBALL ; \
    rm -rf $TARBALL ; \
    cd $TOOL_NAME-$TOOL_VERSION ; \
    make prefix=$TOOLS/$TOOL_NAME/$TOOL_VERSION install ; \
    cd ../ ; \
    rm -rf $TOOL_NAME-$TOOL_VERSION ; \
    ln -s $TOOLS/$TOOL_NAME/$TOOL_VERSION $TOOLS/$TOOL_NAME/current



############
# SAMTOOLS #
############

ENV TOOL_NAME=samtools
ENV TOOL_VERSION=1.8
ENV TARBALL_LOCATION=https://github.com/samtools/$TOOL_NAME/releases/download/$TOOL_VERSION/
ENV TARBALL=$TOOL_NAME-$TOOL_VERSION.tar.bz2
ENV DEST=$TOOLS/$TOOL_NAME/$TOOL_VERSION
ENV PATH=$TOOLS/$TOOL_NAME/$TOOL_VERSION/bin:$PATH

# INSTALL
RUN wget $TARBALL_LOCATION/$TARBALL ; \
    tar xf $TARBALL ; \
    rm -rf $TARBALL ; \
    cd $TOOL_NAME-$TOOL_VERSION ; \
    make prefix=$TOOLS/$TOOL_NAME/$TOOL_VERSION install ; \
    cd ../ ; \
    rm -rf $TOOL_NAME-$TOOL_VERSION ; \
    ln -s $TOOLS/$TOOL_NAME/$TOOL_VERSION $TOOLS/$TOOL_NAME/current



############
# BEDTOOLS #
############

ENV TOOL_NAME=bedtools
ENV TOOL_VERSION=2.27.1
ENV TARBALL_LOCATION=https://github.com/arq5x/bedtools2/releases/download/v$TOOL_VERSION
ENV TARBALL=$TOOL_NAME-$TOOL_VERSION.tar.gz
ENV TARBALL_FOLDER=bedtools2
ENV DEST=$TOOLS/$TOOL_NAME/$TOOL_VERSION
ENV PATH=$TOOLS/$TOOL_NAME/$TOOL_VERSION/bin:$PATH

# INSTALL
RUN wget $TARBALL_LOCATION/$TARBALL ; \
    tar xf $TARBALL ; \
    rm -rf $TARBALL ; \
    cd $TARBALL_FOLDER ; \
    make prefix=$TOOLS/$TOOL_NAME/$TOOL_VERSION install ; \
    cd ../ ; \
    rm -rf $TARBALL_FOLDER ; \
    ln -s $TOOLS/$TOOL_NAME/$TOOL_VERSION $TOOLS/$TOOL_NAME/current ;


##########
# PICARD #
##########

ENV TOOL_NAME picard
ENV TOOL_VERSION 2.18.5
ENV JAR_LOCATION https://github.com/broadinstitute/picard/releases/download/$TOOL_VERSION
ENV JAR picard.jar
ENV DEST $TOOLS/$TOOL_NAME/$TOOL_VERSION
ENV PATH "$TOOLS/$TOOL_NAME/$TOOL_VERSION/bin:$PATH"

# INSTALL
RUN wget $JAR_LOCATION/$JAR ; \
    mkdir -p $TOOLS/$TOOL_NAME/$TOOL_VERSION/bin ; \
    mv $JAR $TOOLS/$TOOL_NAME/$TOOL_VERSION/bin ; \
    ln -s $TOOLS/$TOOL_NAME/$TOOL_VERSION/bin/$JAR /$JAR ; \
    ln -s $TOOLS/$TOOL_NAME/$TOOL_VERSION $TOOLS/$TOOL_NAME/current ;



######################
# YUM REMOVE & CLEAR #
######################

RUN yum erase -y $YUM_REMOVE ; yum clean all ;




##############################
# WORKDIR / ENTRYPOINT / CMD #
##############################


WORKDIR "/data"

CMD [ "find", "/tools", "-maxdepth", "2", "-mindepth", "2", "-type", "d" ]
