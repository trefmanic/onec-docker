#!/bin/bash
set -e

# Проверяем переменные окружения
if [ -z "$ONEC_USERNAME" ]
then
    echo "ONEC_USERNAME not set"
    exit 1
fi

if [ -z "$ONEC_PASSWORD" ]
then
    echo "ONEC_PASSWORD not set"
    exit 1
fi

if [ -z "$ONEC_VERSION" ]
then
    echo "ONEC_VERSION not set"
    exit 1
fi

SRC=$(curl -c /tmp/cookies.txt -s -L https://releases.1c.ru)
ACTION=$(echo "$SRC" | grep -oP '(?<=form method="post" id="loginForm" action=")[^"]+(?=")')
EXECUTION=$(echo "$SRC" | grep -oP '(?<=input type="hidden" name="execution" value=")[^"]+(?=")')
VERSION_PATH=$(echo $ONEC_VERSION | sed 's/\./_/g')

curl -s -L \
    -o /dev/null \
    -b /tmp/cookies.txt \
    -c /tmp/cookies.txt \
    --data-urlencode "inviteCode=" \
    --data-urlencode "execution=$EXECUTION" \
    --data-urlencode "_eventId=submit" \
    --data-urlencode "username=$ONEC_USERNAME" \
    --data-urlencode "password=$ONEC_PASSWORD" \
    https://login.1c.ru"$ACTION"

if ! grep -q "TGC" /tmp/cookies.txt

then
    echo "Auth failed"
    exit 1
fi

# Выбор типа установки и формирование ссылки
case "$installer_type" in
  # Платформа 1С (сервер, толстый клиент)
  server)
    echo "$0: Generating $installer_type download link"
    # Формирование ссылки на загрузку
    DOWNLOAD_LINK=$(curl -v -s -G \
                    -b /tmp/cookies.txt $URL \
                    --data-urlencode "nick=Platform83" \
                    --data-urlencode "ver=$ONEC_VERSION" \
                    --data-urlencode "path=Platform\\$VERSION_PATH\\server64_$VERSION_PATH.tar.gz" \
                    https://releases.1c.ru/version_file \
                    | grep -o '<a href="https://dl.*>Скачать дистрибутив</a>' \
                    | uniq | sed -e 's/^<a href="//g' -e 's/">.*$//g')
  ;;
  # Тонкий клиент
  thinclient)
    echo "$0: Generating $installer_type download link"
    # Формирование ссылки на загрузку
    DOWNLOAD_LINK=$(curl -s -G \
                    -b /tmp/cookies.txt $URL \
                    --data-urlencode "nick=Platform83" \
                    --data-urlencode "ver=$ONEC_VERSION" \
                    --data-urlencode "path=Platform\\$VERSION_PATH\\thin.client64_$VERSION_PATH.tar.gz" \
                    https://releases.1c.ru/version_file \
                    | grep -o '<a href="https://dl.*>Скачать дистрибутив</a>' \
                    | uniq | sed -e 's/^<a href="//g' -e 's/">.*$//g')
  ;;
esac

# Процесс загрузки
echo "$0: Downloading $installer_type"
curl -b /tmp/cookies.txt -o $installer_type.tar.gz -L "$DOWNLOAD_LINK"

# Очистка куков
rm /tmp/cookies.txt

exit 0
