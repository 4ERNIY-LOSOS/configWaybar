#!/bin/bash
# Скрипт для получения текущей загрузки GPU Nvidia

# Выполняем nvidia-smi, запрашиваем только утилизацию GPU,
# в формате CSV, без заголовка и без единиц измерения (знака '%')
utilization=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)

# Проверяем, не пустой ли вывод (на случай ошибки nvidia-smi)
if [ -n "$utilization" ]; then
    echo "$utilization"
else
    echo "N/A" # Или другое значение по умолчанию/ошибки
fi
