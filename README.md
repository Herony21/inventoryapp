# InventoryApp

## Sistema de Gestión de Inventarios y Personal:
Aplicación desarrollada para la gestión de trabajadores e inventarios, orientada a entornos empresariales que requieren control de usuarios, seguridad en accesos y manejo de información en la nube.
Proyecto desarrollado como parte de mi formación en Ingeniería de Sistemas, enfocado en buenas prácticas, arquitectura modular y uso de servicios modernos.

## Descripción del proyecto:
InventoryApp es una solución digital que permite administrar usuarios mediante roles, controlar accesos y visualizar información relevante del personal.
El sistema implementa autenticación segura, almacenamiento en la nube y una estructura escalable que permite futuras ampliaciones como control de stock, reportes y analítica.
                            
Este proyecto demuestra mi capacidad para diseñar soluciones funcionales, estructuradas y alineadas a necesidades reales.

## Funcionalidades principales:
- Autenticación de usuarios con control de roles (Administrador / Trabajador)
- Registro y gestión de trabajadores
- Listado dinámico de usuarios desde base de datos en la nube
- Creación, lectura, actualización y eliminación de datos (CRUD)
- Gestión de sesiones
- Visualización de estadísticas
- Arquitectura modular y escalable
- Interfaz clara y funcional
  
## Tecnologías utilizadas:
-Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Supabase Auth
- Riverpod (gestión de estados)

## Estructura del proyecto
lib/
│
├── auth/
│   ├── admin_login_page.dart
│   ├── worker_login_page.dart
│   ├── create_worker_page.dart
│   ├── workers_list_page.dart
│   ├── admins_list_page.dart
│   └── auth_controller.dart
│
├── presentation/
│   ├── auth/login_page.dart
│   └── widgets/notification_bell.dart
│
├── stats/
│   └── worker_stats_page.dart
│
└── workers_list_page.dart

## Perfiles de usuario

Administrador:
- Inicio de sesión seguro
- Registro de trabajadores
- Gestión de usuarios
- Visualización de estadísticas
- Control de accesos

Trabajador:
- Inicio de sesión personal
- Visualización de información propia
- Acceso a métricas

## Instalación y ejecución

1.Clonar el repositorio:
git clone https://github.com/Herony21/inventoryapp.git

2.Instalar dependencias:
flutter pub get

3.Ejecutar aplicación
flutter run

## Objetivo del proyecto:
"Desarrollar una solución real que permita aplicar conocimientos en desarrollo móvil, bases de datos en la nube, autenticación y arquitectura de software, enfocada en contextos empresariales."

## Autor:

Herony Anel Delgado Campos
Estudiante de Ingeniería de Sistemas
Desarrollador Web y Mobile

Correo: heronydelgadocampos50@gmail.com

LinkedIn: https://www.linkedin.com/in/herony-delgado-campos-1019a7278

Nota:

"Este proyecto forma parte de mi portafolio profesional para prácticas pre-profesionales."
