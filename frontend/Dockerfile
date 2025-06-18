# frontend/Dockerfile (CORREGIDO - Versión 3)

# --- STAGE 1: Build Flutter Web application ---
FROM dart:stable AS build-stage

# Establece un usuario no-root para Flutter (opcional, pero puede resolver permisos)
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN addgroup --gid ${GROUP_ID} appuser && adduser --uid ${USER_ID} --ingroup appuser --shell /bin/bash --disabled-password --gecos "" appuser
USER appuser
WORKDIR /home/appuser/app

# Instala Git, curl, unzip, y sudo (para futuras necesidades si cambias a root temporalmente)
# Locales para evitar warnings y asegurar compatibilidad
# NOTA: dart:stable es Debian-based, así que usamos apt-get
USER root # Temporarily switch to root for package installation
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    unzip \
    sudo \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Configura las locales para evitar la advertencia de setlocale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Switch back to the appuser
USER appuser

# Clona el SDK de Flutter
# Usa un URL específico de una versión estable para mayor consistencia
# Puedes cambiar '3.19.6' por la versión de Flutter que uses o la 'stable' más reciente
RUN git clone https://github.com/flutter/flutter.git -b 3.19.6 --depth 1 /home/appuser/flutter_sdk

# Añade Flutter a tu PATH
ENV PATH="/home/appuser/flutter_sdk/bin:${PATH}"

# Habilita Flutter web y actualiza el SDK
# Esto es importante para que el SDK esté completamente configurado para web builds
RUN flutter channel stable && \
    flutter upgrade && \
    flutter config --enable-web

# Copia los archivos pubspec y obtén las dependencias para aprovechar el cache de Docker
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copia el resto del código fuente de Flutter
COPY . .

# Construye la aplicación Flutter para web en modo release
# Si la build falla sin un mensaje claro, intenta añadir --verbose
RUN flutter build web --release

# Mueve la salida a un directorio más explícito para la siguiente etapa
RUN mv build/web build_output

# --- STAGE 2: Serve with Nginx ---
FROM nginx:alpine AS serve-stage

# Copia la configuración de Nginx al contenedor
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copia los archivos de construcción de Flutter desde la etapa anterior
COPY --from=build-stage /home/appuser/app/build_output /usr/share/nginx/html

# Expone el puerto 8097 donde Nginx servirá la aplicación
EXPOSE 8097

# Comando para iniciar Nginx en primer plano
CMD ["nginx", "-g", "daemon off;"]