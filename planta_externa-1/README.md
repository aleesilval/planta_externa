# Planta Externa

Este proyecto es una aplicación móvil desarrollada con Flutter que permite a los usuarios ingresar datos a través de un formulario, adjuntar fotos, visualizar los datos en tablas y exportar la información en un archivo PDF.

## Estructura del Proyecto

El proyecto está organizado en varias carpetas y archivos, cada uno con una función específica:

- **lib/**: Contiene el código fuente de la aplicación.
  - **main.dart**: Punto de entrada de la aplicación.
  - **screens/**: Contiene las pantallas de la aplicación.
    - **formulario_page.dart**: Pantalla para ingresar datos y adjuntar fotos.
    - **tabla_page.dart**: Pantalla para mostrar los datos en formato de tabla.
    - **pdf_export_page.dart**: Pantalla para exportar datos a PDF.
  - **widgets/**: Contiene widgets reutilizables.
    - **formulario_form.dart**: Widget para el formulario de entrada de datos.
    - **foto_preview.dart**: Widget para mostrar una vista previa de las fotos.
    - **tabla_datos.dart**: Widget para presentar los datos en formato de tabla.
  - **models/**: Contiene los modelos de datos.
    - **datos_model.dart**: Modelo que representa la estructura de los datos ingresados.
  - **utils/**: Contiene utilidades y funciones auxiliares.
    - **pdf_generator.dart**: Funciones para generar archivos PDF.

## Instrucciones de Instalación

1. Clona el repositorio en tu máquina local.
2. Navega a la carpeta del proyecto.
3. Ejecuta `flutter pub get` para instalar las dependencias necesarias.
4. Conecta un dispositivo o inicia un emulador.
5. Ejecuta `flutter run` para iniciar la aplicación.

## Uso

- En la pantalla principal, completa el formulario con el nombre y la descripción.
- Adjunta fotos desde la cámara o la galería.
- Navega a la pantalla de tabla para ver los datos ingresados.
- Utiliza la opción de exportar para generar un archivo PDF con la información.

## Dependencias

Este proyecto utiliza las siguientes dependencias:

- `image_picker`: Para seleccionar imágenes de la galería o tomar fotos con la cámara.
- `pdf`: Para crear archivos PDF.
- `printing`: Para imprimir o compartir archivos PDF generados.

## Contribuciones

Las contribuciones son bienvenidas. Si deseas contribuir, por favor abre un issue o envía un pull request.