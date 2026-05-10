#!/bin/bash

BASEDIR=/config
source /$BASEDIR/import.env

# --- CONFIGURACIÓN ---
GOTIFY_URL="$GOTIFY"

# En este caso, la carpeta import de beets es la misma carpeta donde descarga slskd,
# y slskd ejecuta un script al finalizar cada descarga. Ese script crea un archivo
# de bloqueo para prevenir que import.sh se ejecute antes de terminar su procesamiento
if [ -f "/import/slskd.lock" ]; then
    echo "[$(date)] slskd.lock presente, abortando." >> $BASEDIR/beets.log
    exit 0
fi


echo "[$(date)] Ejecutando importación inicial de Beets..." >> $BASEDIR/beets.log

# Ejecutar Beets
beet import -q /import >> $BASEDIR/beets.log

beet update

mkdir -p /music/Salteados

find /import -type f -not -path "/music/Salteados/*" -exec mv -t "/music/Salteados" {} +

# Notificar
/usr/bin/curl -s -X POST "$GOTIFY_URL" \
    -F "title=Beets" \
    -F "message=El escaneo de inicio ha finalizado." \
    -F "priority=5" > /dev/null

echo "[$(date)] Proceso completado." >> $BASEDIR/beets.log
