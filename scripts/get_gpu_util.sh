#!/bin/bash

# Получаем общую загрузку GPU
gpu_util_percent=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{print $1}' | sed 's/[^0-9]*//g')
gpu_util_percent=${gpu_util_percent:-N/A}

# Формируем заголовок для tooltip
tooltip_text="GPU Load: ${gpu_util_percent}%\n"

# Получаем данные о процессах, использующих GPU
# Заголовки из pmon: # gpu pid type fb ccpm command
#                       Idx   #  C/G MB   MB   name
processes_info=$(nvidia-smi pmon -c 1 -s m | awk 'NR > 2 {
    pid=$2;       # PID процесса
    fb_usage=$4;  # Использование Framebuffer (MB)

    # Собираем имя команды, начиная с 6-го поля до конца строки
    cmd=$6;
    for (i=7; i<=NF; i++) {
        cmd = cmd " " $i;
    }

    # Если имя команды пустое или "-", ставим "N/A"
    if (cmd == "" || cmd == "-") cmd = "N/A";
    # Если использование памяти пустое или "-", ставим "0"
    if (fb_usage == "" || fb_usage == "-") fb_usage = "0";

    print pid, fb_usage, cmd;
}' | sort -k2 -nr | head -n 5)


if [ -n "$processes_info" ]; then
    tooltip_text+="\nTop GPU Processes:\n"
    # Форматируем каждую строку из processes_info
    formatted_processes=$(echo "$processes_info" | awk '{
        # $1=pid, $2=fb_usage, $3...=cmd (все остальное после $2 это команда)
        pid_val=$1;
        fb_val=$2;
        cmd_display = $3; # Начинаем собирать команду с 3-го поля
        for (i=4; i<=NF; i++) cmd_display = cmd_display " " $i;

        # Если cmd_display все еще "N/A" или пусто, используем PID
        if (cmd_display == "N/A" || cmd_display == "") cmd_display="PID:"pid_val;

        # Обрезаем очень длинные имена процессов для лучшего отображения
        if (length(cmd_display) > 25) cmd_display = substr(cmd_display, 1, 22) "...";

        printf "%d. %s - %s MiB\n", NR, cmd_display, fb_val
    }')
    tooltip_text+="$formatted_processes"
else
    tooltip_text+="\nNo process data available or error in parsing."
fi

# Используем jq для корректного формирования JSON
JSON_TEXT="$gpu_util_percent"
JSON_TOOLTIP=$(echo -e "$tooltip_text") # echo -e для обработки \n

jq -n \
  --arg text "$JSON_TEXT" \
  --arg tooltip "$JSON_TOOLTIP" \
  '{text: $text, tooltip: $tooltip}'
