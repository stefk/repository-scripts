#!bin/bash

log() { echo -e "$1"; }
fail() { echo -e "Release process failed" && exit 1; }
succeed() { echo -e "Release process succeeded" && exit 0; }

composerjson=$1

#trap fail ERR
log 'Creating tmp dir...'
    rm -rf tmp 
    mkdir tmp
    cd tmp
log 'Downloading claroline/Claroline archive...'
    wget https://github.com/claroline/Claroline/archive/master.zip
    unzip master.zip
    cd Claroline-master
log 'Installing dependencies...'
    composer require composer/composer dev-master --prefer-dist
    composer require claroline/bundle-recorder "~3.0" --prefer-dist
    
    if [ $composerjson =~ "min" ]; then
        composerjson='full'
    fi

    log "Copying composer $composerjson"
    cp composer.json.$composerjson composer.json

    
    cp app/config/parameters.yml.dist app/config/parameters.yml
    composer update --no-dev --prefer-dist -o
log 'Removing dev files and adding placeholders...'
    rm .gitignore
    rm .jshintignore
    rm .travis.yml
    rm app/config/operations.xml*
    rm app/phpunit*
    rm behat.yml.dist
    rm composer.json.full
    rm composer.json.min
    rm web/app_dev.php
    rm web/app_test.php
    rm -rf .git
    rm -rf **/.git
    rm -rf app/build
    rm -rf app/dev
    rm -rf app/cache/*
    rm -rf app/logs/*
    rm -rf test
    rm -rf web/bundles
    touch app/cache/.gitkeep
    touch app/logs/.gitkeep
log 'Zipping and publishing release...'
    versionRegex='"name":\s*"claroline\/core-bundle",\s*"version":\s*"([^"]+)"'
    installedPackages=`cat vendor/composer/installed.json`
    if [[ $installedPackages =~ $versionRegex ]]; then
        version="${BASH_REMATCH[1]}"
    else
        echo "Cannot found core bundle version"
        fail
    fi
    if [ -f "releases/$releaseName.zip" ]; then
        time=$(date +%s)
        releaseName="claroline-connect-$version-$time-$composerjson"
    else
        releaseName="claroline-connect-$version-$composerjson"
    fi
    mkdir "../$releaseName"
    cp -R * "../$releaseName/"
    cd ..
    zip -r "$releaseName.zip" $releaseName
    cp "$releaseName.zip" ../releases/
log 'Removing tmp directory...'
    cd ..
    rm -r tmp

succeed


