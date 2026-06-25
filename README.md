# beets-config

Configuración completa de [beets](https://beets.io/) para homelab, usando la imagen Docker de [LinuxServer](https://docs.linuxserver.io/images/docker-beets/). Incluye importación automática cada 30 minutos, identificación por huella de audio (AcoustID/Chromaprint), descarga de carátulas, letras, géneros y notificaciones via Gotify.

---

## Archivos

| Archivo | Descripción |
|---|---|
| `docker-compose.yml` | Definición del contenedor |
| `config.yaml` | Configuración principal de beets |
| `import.sh` | Script de importación automática |
| `import.env` | Variables de entorno del script (Gotify) |
| `99-beets-setup` | Script de inicio del contenedor (instala el cron e importación inicial) |
| `abc` | Archivo de crontab del usuario `abc` |

---

## Funcionamiento general

Al iniciar el contenedor, `99-beets-setup` se ejecuta automáticamente gracias al mecanismo `custom-cont-init.d` de LinuxServer. Este script instala el crontab y lanza una importación inicial.

A partir de ahí, `import.sh` corre cada 30 minutos via cron. El script:

1. Verifica que `slskd.lock` no esté presente (para no interferir con descargas en curso de slskd)
2. Ejecuta `beet import -q /import`
3. Ejecuta `beet update` (sincroniza los tags editados externamente con la base de datos)
4. Notifica via Gotify al finalizar

---

## Instalación

### 1. Clonar el repositorio

```bash
git clone https://codeberg.org/osdaeg/beets-config.git
cd beets-config
```

### 2. Configurar las variables de entorno

```bash
cp import.env.example import.env
```

Editar `import.env`:

```bash
GOTIFY="http://TuIPDeGotify:TuPortDeGotify/message?token=TuTokenDeGotify"
```

### 3. Configurar AcoustID

En `config.yaml`, reemplazar la API key:

```yaml
acoustid:
    apikey: TU_API_KEY_AQUI
```

Registrar una aplicación en [acoustid.org/new-application](https://acoustid.org/new-application).

### 4. Configurar docker-compose.yml

```bash
cp docker-compose.yml.example docker-compose.yml
```

Ajustar las rutas de los volúmenes:

```yaml
volumes:
  - /ruta/a/tu/configuracion/de/beets:/config
  - /ruta/a/custom-cont-init.d:/custom-cont-init.d
  - /ruta/a/tu/libreria/musical:/music
  - /ruta/a/la/carpeta/a/importar:/import
```

Y el nombre de tu red Docker:

```yaml
networks:
  - TuRed
```

### 5. Copiar los archivos de configuración

Los siguientes archivos deben estar en la carpeta que montás como `/config`:

```
config.yaml
import.sh
import.env
```

El archivo `99-beets-setup` debe estar en la carpeta montada como `/custom-cont-init.d`.

El archivo `abc` puede ignorarse — es generado automáticamente por `99-beets-setup` en `/config/crontabs/abc`.

### 6. Dar permisos de ejecución

```bash
chmod +x import.sh
chmod +x 99-beets-setup
```

### 7. Levantar el contenedor

```bash
docker compose up -d
```

---

## Plugins activos

| Plugin | Función |
|---|---|
| `fetchart` | Descarga carátulas desde CoverArtArchive, iTunes, Amazon |
| `embedart` | Embebe la carátula dentro del archivo de audio |
| `lyrics` | Descarga letras desde Google, Genius, Musixmatch |
| `lastgenre` | Asigna géneros desde Last.fm |
| `chroma` | Genera huella de audio con fpcalc (Chromaprint) |
| `mbsync` | Sincroniza metadata con MusicBrainz |
| `scrub` | Limpia tags basura antes de importar |
| `web` | Expone la API REST en el puerto 8337 |
| `info` | Muestra información de archivos por CLI |
| `inline` | Permite campos calculados en la configuración |

---

## Estructura de archivos resultante

```
$albumartist/($year) $album/$track - $title   ← álbumes
Non-Album/$artist/$title                        ← singletons
Compilations/$album/$track - $title             ← compilaciones
```

---

## Recursos útiles

- [Script post-descarga para SLSKD](https://codeberg.org/osdaeg/slskd-finish-script)
- [Editor de metadatos Taggerr](https://codeberg.org/osdaeg/taggerr)

---

## Integración con slskd

La carpeta `/import` de beets es la misma carpeta de descargas de slskd. Para evitar que beets importe archivos mientras slskd todavía los está procesando, el script de post-descarga de slskd crea un archivo `slskd.lock` en `/import`. `import.sh` verifica su presencia antes de correr y aborta si existe.

---

## Integración con Taggerr

[Taggerr](https://codeberg.org/osdaeg/taggerr) es un editor de tags web complementario. Edita los archivos directamente en disco; `beet update` (incluido en `import.sh`) sincroniza esos cambios con la base de datos de beets en cada ciclo.

---

## Logs

```bash
# Ver log de importaciones
docker exec beets tail -f /config/beets.log

# Ver logs del contenedor
docker logs beets
```

---

## Comandos útiles

```bash
# Importar manualmente
docker exec beets beet import /import

# Actualizar la base de datos con los tags actuales de los archivos
docker exec beets beet update

# Buscar en la biblioteca
docker exec beets beet ls "artista"

# Ver estado de la API web
curl http://localhost:8337/stats
```
