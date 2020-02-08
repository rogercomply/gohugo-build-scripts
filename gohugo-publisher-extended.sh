#!/usr/bin/env bash

# A Hugo build and deploy script supporting onion domains.
# Source: https://blog.paranoidpenguin.net/how-to-configure-hugo-as-a-tor-hidden-service/

# Copyright 2020 ParanoidPenguin.net
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING file for more details.

GOHUGO=$(which hugo)
MINIFY=${HOME}/go/bin/minify

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
ONION_V2_URI=http://slackiuxopmaoigo.onion
ONION_V2_DIR=onionv2

ONION_V3_TITLE=Slackiuxopmaoigo.onion
ONION_V3_URI=http://4hpfzoj3tgyp2w7sbe3gnmphqiqpxwwyijyvotamrvojl7pkra7z7byd.onion
ONION_V3_DIR=onionv3

function prepare ()
{
	PUBLISH_DIR=$1

	if [ -d "${CONTENT_DIR}" ]
	then
		if [ -d "${CONTENT_DIR}/${PUBLISH_DIR}" ]
		then
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

	cd $CONTENT_DIR && \
	$GOHUGO --destination=${CONTENT_DIR}/${PUBLISH_DIR}
	sed -i "/<meta name=\"robots\" content=\"noindex,follow\"\/>/d" ${CONTENT_DIR}/${PUBLISH_DIR}/index.html

	compress $PUBLISH_DIR
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

    cd $CONTENT_DIR && \
    HUGO_TITLE=${TITLE} \
    HUGO_PARAMS_AUTHORBOX="false" \
    HUGO_PARAMS_SHARE_FACEBOOK="false" \
    HUGO_PARAMS_SHARE_TWITTER="false" \
    HUGO_PARAMS_SHARE_REDDIT="false" \
    HUGO_PARAMS_SHARE_LINKEDIN="false" \
	$GOHUGO \
	--destination=${CONTENT_DIR}/${PUBLISH_DIR} \
	--baseURL=${ONION_URI}/ \
	--disableKinds=sitemap,RSS

	rm -Rf ${CONTENT_DIR}/${PUBLISH_DIR}/${STATIC_DIR}
	sed -i "/<meta name=\"robots\" content=\"noindex,follow\"\/>/d" ${CONTENT_DIR}/${PUBLISH_DIR}/index.html
	sed -i "/<link rel=\"alternate\" type=\"application\/rss+xml\" href=\"\/index.xml\" title=\"${TITLE}\">/d" ${CONTENT_DIR}/${PUBLISH_DIR}/index.html
	find ${CONTENT_DIR}/${PUBLISH_DIR} \( -name "*.html" -o -name "*.xml" -o -name "*.css" \) -exec sed -i "s/${BLOG_URI_ESCAPED}/${ONION_URI_ESCAPED}/gI" {} \;

	compress $PUBLISH_DIR
	publish $PUBLISH_DIR
}

function compress ()
{
	PUBLISH_DIR=$1

	find ${CONTENT_DIR}/${PUBLISH_DIR} -name "*.html" -exec ${MINIFY} --html-keep-document-tags --html-keep-end-tags --html-keep-default-attrvals -o {} {} \;
	find ${CONTENT_DIR}/${PUBLISH_DIR} -name "*.xml" -exec ${MINIFY} --xml-keep-whitespace --html-keep-document-tags --html-keep-end-tags --html-keep-default-attrvals -o {} {} \;
	find ${CONTENT_DIR}/${PUBLISH_DIR} -name "*.css" -exec ${MINIFY} --type=css -o {} {} \;
	find ${CONTENT_DIR}/${PUBLISH_DIR} -name "*.js" -exec ${MINIFY} --type=js -o {} {} \;
}

function publish ()
{
	PUBLISH_DIR=$1

	rsync -azP --chown=${REMOTE_USER}:${REMOTE_GROUP} ${CONTENT_DIR}/${PUBLISH_DIR}/ ${SSH_USER}@${SSH_SERVER}:${REMOTE_DIR}/${PUBLISH_DIR}
}

clear
clearnet_builder $BLOG_DIR
onion_builder $ONION_V2_DIR $ONION_V2_URI $ONION_V2_TITLE
onion_builder $ONION_V3_DIR $ONION_V3_URI $ONION_V3_TITLE
