# Contexto del Proyecto: Sistema de Trabajos

Este proyecto es una aplicación Flutter de gestión para una gráfica/imprenta.

## Arquitectura

El proyecto sigue una estructura basada en carpetas dentro de `/lib`:

- `models/`: Modelos de datos (orden_model.dart, orden_item_model.dart).
- `services/`: Lógica de negocio y servicios externos (PocketBase, Auth, Temas, Impresión).
- `views/`: Interfaz de usuario dividida por módulos:
  - `auth/`: Login.
  - `cashier/`: Módulo de caja (lista de pagos, gestión de pendientes, tickets).
  - `designer/`: Módulo para diseñadores (formulario de POS).
  - `shared/`: Widgets y vistas compartidas (Home, Temas).
- `utils/`: Helpers para exportación e impresión multiplataforma.

## Tecnologías Principales

- **Framework:** Flutter (Material Design).
- **Backend:** PocketBase (`pocketbase` SDK).
- **Gestión de Estado:** `provider`.
- **Funcionalidades Clave:**
  - Impresión térmica (`esc_pos_printer`).
  - Exportación de datos a Excel.
  - Gestión de temas (Light/Dark).
  - Multiplataforma (Windows/Web/Mobile).

## Reglas de desarrollo

- Mantener la separación entre `views` y `services`.
- Usar `provider` para el estado global (AuthProvider, ThemeProvider).
- Para cambios en el diseño o UI, referirse siempre a `app_theme.dart` para asegurar consistencia.
