#!/bin/bash

# Сообщение о начале теста
notify-send "Speedtest" "Запускаю тест скорости интернета..." -i network-transmit-receive -t 3000 # -t 3000 (3 секунды)

# Запускаем speedtest-cli, берем только нужные строки
# Опция --secure используется для HTTPS, что может быть немного медленнее, но надежнее
# Опция --simple выводит только основные данные
result=$(speedtest-cli --simple --secure 2>/dev/null) # 2>/dev/null чтобы скрыть индикатор прогресса из stderr

if [ -z "$result" ]; then
    notify-send "Speedtest Error" "Не удалось выполнить тест скорости." -i dialog-error -u critical
    exit 1
fi

download=$(echo "$result" | grep "Download:" | awk '{print $2 " " $3}')
upload=$(echo "$result" | grep "Upload:" | awk '{print $2 " " $3}')
ping=$(echo "$result" | grep "Ping:" | awk '{print $2 " " $3}')

if [ -z "$download" ] || [ -z "$upload" ] || [ -z "$ping" ]; then
    notify-send "Speedtest Error" "Не удалось разобрать результаты теста." -i dialog-warning -u normal
    exit 1
fi

# Формируем и показываем уведомление
# Иконку можно подобрать, например, 'network-transmit-receive', 'network-wired', 'network-wireless'
notify-send "Speedtest Result 🚀" \
"Ping: $ping\nDownload: $download\nUpload: $upload" \
-i network-transmit-receive -u normal -t 10000 # -t 10000 (10 секунд)

exit 0
