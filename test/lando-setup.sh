#!/bin/bash

# exit on error
set -e

WP_VERSION="${WP_VERSION:-4.9.7}"
PHP_VERSION="${PHP_VERSION:-7.0}"

cd "$(dirname "$0")"
cd ..

# Hack - awaiting https://github.com/lando/lando/pull/750
perl -pi -we "s/^  php: .*/  php: '$PHP_VERSION'/" .lando.yml

lando start -v
lando wp --version || lando bash test/install-wp-cli.sh
rm -rf test/site/[a-z]*
lando wp core download \
    --path=test/site/ \
    --version=$WP_VERSION

lando wp config create \
    --path=test/site/ \
    --dbname=wordpress \
    --dbuser=wordpress \
    --dbpass=wordpress \
    --dbhost=database

lando wp config set \
    --path=test/site/ \
    --type=constant \
    --raw \
    WP_AUTO_UPDATE_CORE false

lando wp config set \
    --path=test/site/ \
    --type=constant \
    --raw \
    WP_DEBUG true

wp_url="$(lando info | grep -A2 '"urls": \[$' | tail -n 1 | cut -d'"' -f2)"
lando wp core install \
    --path=test/site/ \
    --url="$wp_url" \
    '--title="My Test Site"' \
    --admin_user="admin" \
    --admin_password="admin" \
    --admin_email="admin@example.com" \
    --skip-email

echo "Testing site URL: $wp_url"

mkdir test/site/wp-content/plugins/switch-to-classicpress
ln -vs \
    ../../../../../switch-to-classicpress.php \
    test/site/wp-content/plugins/switch-to-classicpress/
ln -vs \
    ../../../../../lib/ \
    test/site/wp-content/plugins/switch-to-classicpress/
lando wp plugin activate \
    --path=test/site/ \
    switch-to-classicpress
