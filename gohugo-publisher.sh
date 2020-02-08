#!/usr/bin/env bash

# A Hugo build and deploy script supporting onion domains.

# Copyright 2020 ParanoidPenguin.net
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING file for more details.

GOHUGO=$(which hugo)

SSH_SERVER=server4.paranoidpenguin.net
SSH_USER=root

REMOTE_DIR=/var/www/blog.paranoidpenguin.net/html
REMOTE_USER=user
REMOTE_GROUP=group

CONTENT_DIR=${HOME}/workspace/hugo
STATIC_DIR=wp-content
BLOG_URI=https://blog.paranoidpenguin.net
BLOG_DIR=blog

ONION_V2_TITLE=Slackiuxopmaoigo.onion
ONION_V2_URI=http://lgy3mqgnwqoou46r.onion
ONION_V2_DIR=onionv2

ONION_V3_TITLE=Slackiuxopmaoigo.onion
ONION_V3_URI=http://o7kg6jl67s27hyccioz3o7y6indb44kutpha4q3si7yl7bl32zrayhad.onion
ONION_V3_DIR=onionv3

function prepare ()
{
    PUBLISH_DIR=$1

    if [ -d "${CONTENT_DIR}" ]
    then
        if [ -d "${CONTENT_DIR}/${PUBLISH_DIR}" ]
        then
            echo "Recursively deleting ${CONTENT_DIR}/${PUBLISH_DIR}"
            rm -Rf ${CONTENT_DIR}/${PUBLISH_DIR}
        fi
    else
        exit 1
    fi
}

function clearnet_builder ()
{
    PUBLISH_DIR=$1
    prepare $PUBLISH_DIR

    echo "Building ${CONTENT_DIR}/${PUBLISH_DIR}"

    cd $CONTENT_DIR && \
    $GOHUGO --destination=${CONTENT_DIR}/${PUBLISH_DIR}

    publish $PUBLISH_DIR
}

function onion_builder ()
{
    PUBLISH_DIR=$1
    ONION_URI=$2
    TITLE=$3

    prepare $PUBLISH_DIR

    BLOG_URI_ESCAPED=(${BLOG_URI//./\\.})
    BLOG_URI_ESCAPED=(${BLOG_URI_ESCAPED//\//\\/})

    ONION_URI_ESCAPED=(${ONION_URI//./\\.})
    ONION_URI_ESCAPED=(${ONION_URI_ESCAPED//\//\\/})

    echo "Building ${CONTENT_DIR}/${PUBLISH_DIR}"

    cd $CONTENT_DIR && \
    HUGO_TITLE=${TITLE} \
    $GOHUGO \
    --destination=${CONTENT_DIR}/${PUBLISH_DIR} \
    --baseURL=${ONION_URI}/ \
    --disableKinds=sitemap,RSS

    echo "Recursively deleting static content from ${CONTENT_DIR}/${PUBLISH_DIR}/${STATIC_DIR}"
    rm -Rf ${CONTENT_DIR}/${PUBLISH_DIR}/${STATIC_DIR}
    find ${CONTENT_DIR}/${PUBLISH_DIR} \( -name "*.html" -o -name "*.xml" -o -name "*.css" \) -exec sed -i "s/${BLOG_URI_ESCAPED}/${ONION_URI_ESCAPED}/gI" {} \;

    publish $PUBLISH_DIR
}

function publish ()
{
    PUBLISH_DIR=$1

    echo "Syncing ${CONTENT_DIR}/${PUBLISH_DIR}/ => ${REMOTE_DIR}/${PUBLISH_DIR}"
    rsync -azzq --chown=${REMOTE_USER}:${REMOTE_GROUP} ${CONTENT_DIR}/${PUBLISH_DIR}/ ${SSH_USER}@${SSH_SERVER}:${REMOTE_DIR}/${PUBLISH_DIR}

    echo "Rsync has finished."
    sleep 3
    clear
}

clear
clearnet_builder $BLOG_DIR
onion_builder $ONION_V2_DIR $ONION_V2_URI $ONION_V2_TITLE
onion_builder $ONION_V3_DIR $ONION_V3_URI $ONION_V3_TITLE
