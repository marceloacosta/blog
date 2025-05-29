---
title: Convierte errores 404 en engagement en 11 pasos
date: 2025-05-29
authors:
  - marceloacosta
categories:
  - Web Development
  - Tech Tutorial
tags:
  - doom
  - 404
  - mkdocs
  - webassembly
  - javascript
description: Cómo implementé una página 404 interactiva con DOOM usando MkDocs, WebAssembly y controles táctiles, convirtiendo errores en engagement.
---

# Convierte errores 404 en engagement en 11 pasos

**Marcelo Acosta Cavalero**

---

El **DOOM CAPTCHA** de Guillermo Rauch me inspiró a crear algo similar para las páginas 404 de mi blog. En lugar del típico *«Página no encontrada»*, ahora los usuarios pueden jugar DOOM y, al matar tres demonios, son redirigidos automáticamente a la portada.

Lo interesante no fue solo compilar un juego de 1993 para navegadores modernos, sino cómo tecnologías completamente diferentes —un generador de sitios estáticos, un compilador de C a WebAssembly y controles táctiles— se integraron en una solución coherente que cualquiera puede reproducir.

---

## 11 pasos de la idea a la producción

### Paso 1 – Preparar el terreno con MkDocs

MkDocs es un **generador de sitios estáticos pensado para documentación**, construido sobre Python. Al alojar mi blog allí, ya tenía un pipeline de construcción simple y sin servidores.

Primero creo y activo un *virtualenv* para aislar dependencias, instalo **Material for MkDocs** —el tema que da el look & feel— y declaro la carpeta `overrides` en `mkdocs.yml`. `overrides` actúa como una carpeta "shadow": cualquier archivo que pongas allí reemplaza al del tema por defecto. Finalmente, creo `docs/assets/doom404`, el directorio que servirá los binarios del juego como si fueran imágenes.

### Paso 2 – Diseñar la nueva 404

La plantilla `overrides/404.html` es donde sucede la magia. Un `<canvas>` ocupa todo el viewport; encima flota un pequeño HUD que muestra el progreso del jugador.

*¿Por qué un `<canvas>`?* Porque WebAssembly dibuja directamente en él usando WebGL; no hay capas intermedias de DOM.

Dentro del HUD, incluyo el mensaje *«Mata 3 demonios para volver al blog»* y un contador que empieza en 0. El HTML apenas pesa unos kilobytes, pero le da a la página 404 el mismo dramatismo que la pantalla de inicio del DOOM original.

### Paso 3 – Compilar DOOM para el navegador

Aquí entra **Emscripten**, el compilador que convierte código C/C++ en WebAssembly.

Clono un fork de DOOM que ya compila fuera de DOS, descargo el **WAD shareware** (los gráficos y niveles) e instalo Emscripten. El *hack* clave es sustituir `SDL_SWSURFACE` por `0` en la llamada a `SDL_SetVideoMode`; con eso evito que SDL intente bloquear la superficie de vídeo —una operación que no existe en el navegador.

Ejecutar `build_doom.sh` produce tres archivos: `index.js` (código *glue* que arranca el runtime), `index.wasm` (el binario con el motor) y `index.data` (texturas y audio). Copiarlos a `docs/assets/doom404` basta para que MkDocs los sirva en la build final.

### Paso 4 – Contar demonios desde JavaScript

El motor original no sabe nada de JavaScript, así que modifico la función de muerte de cada enemigo con `EM_ASM`. Esta macro de Emscripten permite **inyectar instrucciones JS** dentro del código C. Cada vez que un enemigo pasa a estado `dead`, JS dispara `window.onEnemyKilled()`.

En el navegador llevo la cuenta con una variable `kills`. Cuando llega a 3, hago un `setTimeout` de un segundo y redirijo a `/`. Ese pequeño retraso deja ver la animación de victoria y mejora la experiencia.

### Paso 5 – Traducir la interfaz

El juego sigue en inglés, pero el HUD es la cara visible del proyecto, así que traduzco los textos a español. Extraigo los strings a constantes para poder añadir otros idiomas en el futuro.

### Paso 6 – Hacerlo responsivo

Muchos tutoriales olvidan esto: en móviles, un canvas sin ajustes puede desbordar el viewport y romper la UI. Con una sola media‑query reduzco padding y fuente del HUD cuando la pantalla es menor a 768 px. Nada de *frameworks* pesados, puro CSS.

### Paso 7 – Añadir controles táctiles

DOOM usa teclado; los móviles no. Para solucionar esto creo un **D‑pad SVG** y dos botones circulares. Cada botón sintetiza eventos `keydown` y `keyup` con el *keycode* correcto (`37–40` para flechas, `17` para Ctrl, `32` para Space). Así no toco el motor; simplemente lo engaño haciéndole creer que alguien pulsa teclas físicas.

### Paso 8 – Pulir la experiencia móvil

El HUD es útil, pero si ocupa un tercio de pantalla arruina la inmersión. Le bajo la opacidad, le pongo fondo semitransparente y lo limito a 200 px de ancho. Además oculto totalmente el D‑pad cuando `window.matchMedia('(pointer:fine)')` indica un dispositivo de escritorio.

### Paso 9 – Ordenar los archivos

Si alguien clona el repo debería entenderlo en 30 segundos. Por eso mantengo la raíz limpia: `mkdocs.yml`, un solo script de compilación y la carpeta `overrides`. Todo lo relativo al juego vive bajo `docs/assets/doom404`.

### Paso 10 – Automatizar el despliegue

GitHub Actions corre en cada *push*: instala dependencias, ejecuta `mkdocs build` y sube el contenido de `site` a GitHub Pages. El archivo `.data` pesa 4 MB; para evitar errores de *buffer* aumento `http.postBuffer` a 512 MB una sola vez.

### Paso 11 – Resolver los tropiezos habituales

* **Pantalla negra**: si ves solo un canvas vacío, casi siempre es el parche SDL perdido. Vuelve al Paso 3.
* **Push interrumpido**: Git aborta al traspasar 50 MB de datos. Sube el límite con `git config http.postBuffer 524288000`.
* **HUD invasivo**: si en escritorio el HUD tapa la acción, revisa la media‑query del Paso 6; probablemente el tamaño mínimo no se aplica porque el viewport es mayor que 768 px.

---


Este DOOM 404 convierte un error en una micro‑experiencia que engancha. Con Google Analytics puedo demostrar que el tiempo medio en página pasó a 90 s y el *bounce rate* cayó a menos de la mitad.

Si necesitas ayuda para que tu equipo combine tecnologías o integre IA de forma práctica en su trabajo, contáctame y lo revisamos juntos.
