# Spec

1. Responsabilidad de cada directorio

| Directorio | Responsabilidad | Descripcion |
|------------|-------------|-----------------|
| cmd/ | Interfaz CLI | Contiene los comandos de Cobra. Se ocupa de interpretar argumentos, flags y opciones, y delegar el trabajo. |
| internal/generator/ | Motor de generación | Es el encargado de crear los directorios, procesar archivos, aplicar variables de plantilla y generar el proyecto final. |
| internal/templates/ | Catálogo de plantillas | Contiene las definiciones, variantes y archivos de cada plantilla. Permite incorporar nuevas tecnologías sin modificar el motor de generación. |
| internal/config/ | Configuración | Permite centralizar las preferencias del CLI, como el gestor de paquetes predeterminado y otras opciones persistentes, si las necesitás. |
| internal/ui/ | Interfaz visual | entraliza los mensajes, estilos, preguntas interactivas y barras de progreso, evitando mezclar la presentación con la generación. |

2. Organizacion de las plantillas

Organización de las plantillas
Separaría las plantillas por tecnología y, dentro de cada una, por lenguaje.

3. Flujo de generacion

    Cobra (cmd/create.go) 
Recibe nombre, plantilla y opciones
             ⬇️
Registry (templates/registry.go)
Resuelve la plantilla solicitada
             ⬇️
Generator (generator/generator.go)
  Procesa y genera los archivos
             ⬇️
    Proyecto generado (Archivos listos para instalar dependencias)

# Uso

Por ejemplo, el usuario podría ejecutar:

```shell
mycli create my-game --template phaser-ts
mycli create my-game --template phaser # (phaser JS)
mycli create mi-app --template vanilla-ts
mycli create mi-app --template vanilla # (vanilla JS)
```

O utilizar el modo interactivo:

```shell
mycli create
```

En este último caso, el CLI podría preguntar el nombre del proyecto, la tecnología, el lenguaje y el gestor de paquetes.

| Comando | Responsabilidad|
|---------|----------------|
| create | Generar un proyecto|
| list | Mostrar las plantillas disponibles|
| version | Mostrar la versión del CLI|
| completion | Generar autocompletado para shells|
| help | Mostrar la ayuda de Cobra|
