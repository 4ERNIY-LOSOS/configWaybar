#!/bin/bash

# Получаем список sinks (устройств вывода)
# Формат: ИНДЕКС<TAB>ДРУЖЕЛЮБНОЕ_ИМЯ (ТЕХНИЧЕСКОЕ_ИМЯ)
sinks_data=$(pactl list sinks)
sinks_menu=""
current_sink_idx=""
current_sink_name=""
current_sink_desc=""

while IFS= read -r line; do
    if [[ "$line" =~ Sink[[:space:]]#([0-9]+) ]]; then
        current_sink_idx="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ Name:[[:space:]](.*) ]]; then
        current_sink_name=$(echo "${BASH_REMATCH[1]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    elif [[ "$line" =~ Description:[[:space:]](.*) ]]; then
        current_sink_desc=$(echo "${BASH_REMATCH[1]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        # Формируем строку для меню, отдавая предпочтение Description
        # Убираем "alsa_output." и другие общие префиксы для краткости
        display_name=$(echo "$current_sink_desc" | sed 's/alsa_output\.//g; s/alsa_card\.//g; s/\.stereo-fallback//g; s/\.analog-stereo//g; s/\.hdmi-stereo//g; s/\.iec958-stereo//g; s/_/-/g; s/\./ /g' | awk '{$1=$1};1')

        # Если описание пустое, используем техническое имя
        if [ -z "$display_name" ]; then
            display_name=$(echo "$current_sink_name" | sed 's/alsa_output\.//g; s/alsa_card\.//g; s/\.stereo-fallback//g; s/\.analog-stereo//g; s/\.hdmi-stereo//g; s/\.iec958-stereo//g; s/_/-/g; s/\./ /g' | awk '{$1=$1};1')
        fi

        sinks_menu="${sinks_menu}${current_sink_idx}\t${display_name} (${current_sink_name})\n"
        current_sink_idx=""
        current_sink_name=""
        current_sink_desc=""
    fi
done <<< "$sinks_data"

# Убираем последнюю новую строку, если она есть
sinks_menu=$(echo -e "${sinks_menu}" | sed '/^$/d')


if [ -z "$sinks_menu" ]; then
    echo "Нет доступных устройств вывода" | wofi --dmenu --prompt "Аудиовыходы:" --insensitive
    exit 1
fi

chosen_sink_line=$(echo -e "$sinks_menu" | wofi --dmenu --prompt "Выберите аудиовыход:" --insensitive --lines 8 --width 600 --height 350)

if [ -z "$chosen_sink_line" ]; then
    exit 0
fi

# Извлекаем индекс выбранного sink. Первая колонка до табуляции.
chosen_sink_identifier=$(echo "$chosen_sink_line" | awk -F'\t' '{print $1}')

# Устанавливаем выбранный sink как устройство по умолчанию
if ! pactl set-default-sink "$chosen_sink_identifier"; then
    echo "Не удалось установить устройство: $chosen_sink_identifier" | wofi --dmenu --prompt "Ошибка:" --insensitive
    exit 1
fi

exit 0
