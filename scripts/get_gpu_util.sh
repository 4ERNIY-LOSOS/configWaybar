#!/bin/bash

# Получаем общую загрузку GPU
gpu_util_percent=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{print $1}' | sed 's/[^0-9]*//g')
gpu_util_percent=${gpu_util_percent:-N/A}

# Формируем заголовок для tooltip
tooltip_text="GPU Load: ${gpu_util_percent}%\n"

# Получаем данные о процессах, использующих GPU
# nvidia-smi pmon -c 1 -s m выводит данные по процессам
# Нам нужны колонки: pid, command, fb_memory_usage (в MiB)
# Пропускаем первые две строки заголовка, затем обрабатываем
# Важно: Имена процессов могут содержать пробелы. awk $9 может взять только первое слово.
# Поэтому собираем имя процесса из $9 и всех последующих полей.
processes_info=$(nvidia-smi pmon -c 1 -s m | awk 'NR > 2 {
    pid=$2;
    fb_usage=$8; # Это колонка fb_memory_usage в MiB

    # Собираем имя команды, начиная с 9-го поля до конца строки
    cmd="";
    for (i=9; i<=NF; i++) {
        cmd = cmd $i (i==NF ? "" : " ");
    }
    # Убираем возможные артефакты типа "-" из fb_usage если процесс не использует память GPU
    if (fb_usage == "-") fb_usage = "0";

    print pid, fb_usage, cmd;
}' | sort -k2 -nr | head -n 5)


if [ -n "$processes_info" ]; then
    tooltip_text+="\nTop GPU Processes:\n"
    # Форматируем каждую строку из processes_info
    formatted_processes=$(echo "$processes_info" | awk '{
        # $1=pid, $2=fb_usage, $3...=cmd
        cmd_display = $3;
        for (i=4; i<=NF; i++) cmd_display = cmd_display " " $i;
        # Обрезаем очень длинные имена процессов для лучшего отображения
        if (length(cmd_display) > 30) cmd_display = substr(cmd_display, 1, 27) "...";
        printf "%d. %s - %s MiB\n", NR, cmd_display, $2
    }')
    tooltip_text+="$formatted_processes"
else
    tooltip_text+="\nNo process data available"
fi

# Используем jq для корректного формирования JSON
# Убедитесь, что jq установлен (sudo pacman -S jq)
JSON_TEXT="$gpu_util_percent"
JSON_TOOLTIP=$(echo -e "$tooltip_text") # echo -e для обработки \n

jq -n \
  --arg text "$JSON_TEXT" \
  --arg tooltip "$JSON_TOOLTIP" \
  '{text: $text, tooltip: $tooltip}'
