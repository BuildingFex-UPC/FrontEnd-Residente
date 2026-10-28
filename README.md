# BuildingFex — App de Residentes (Flutter)

Aplicación móvil dirigida a los residentes del condominio BuildingFex. Está
construida con Flutter + Riverpod y se comunica con el mismo backend que la app
de administradores (Jetpack Compose), sin requerir cambios del lado del servidor.

La funcionalidad de administrador vive en la app Compose (`../Clases/FrontEnd`);
esta app es solo para residentes. Las cuentas de administrador tienen bloqueado
el inicio de sesión aquí (`err.ADMIN_LOGIN_BLOCKED`), y los residentes tienen
bloqueado el acceso a la app Compose (`err.RESIDENT_LOGIN_BLOCKED`).

## Funcionalidades (7 pantallas)

- **Inicio de sesión + activación por invitación** — ingresa con correo y
  contraseña, o activa una cuenta de residente con un código de invitación
  (formato `304-k7m2`; pega el mensaje completo y el código se extrae solo).
- **Panel** — saludo, saldo pendiente, conteo de incidencias
  (abiertas/en curso/resueltas), reservas de hoy y próximas, anuncios activos.
- **Finanzas** — saldo pendiente, total pagado, cuotas consolidadas (recibos +
  cuotas vía `mapFees`), Mercado Pago Checkout Pro (flujo demo o pago real en
  WebView con confirmación por parámetro de redirección) y historial de pagos.
- **Espacios comunes** — consulta los espacios publicados, elige una fecha y un
  horario con **selectores de fecha y hora** (se muestran los horarios ya
  reservados) y reserva con validación de campos, de horario y de solapamiento
  en el cliente.
- **Mis reservas** — edita la lista de invitados de cada reserva (máx. 5),
  muestra el QR de registro de invitados y comparte el enlace de invitación
  (vence 25 minutos después del inicio).
- **Incidencias** — reporta nuevas incidencias, revisa su estado, edita la
  descripción y elimínalas.
- **Soporte** — catálogo de preguntas frecuentes + chat de soporte (crea un
  ticket y agrega mensajes).
- **Ajustes** — perfil, **edición de datos de cuenta** (nombre, DNI, dirección
  y piso; el correo no es editable), cambio de contraseña, selector de idioma
  (ES/EN) y cierre de sesión.

## Arquitectura

Clean Architecture por feature + patrón repositorio + estado con Riverpod
(Notifier/StateNotifier) + inyección de dependencias manual
(`lib/core/repositories.dart`).

- `lib/core/` — cliente API (dio + interceptor Bearer/401 + mapeo de errores con
  `apiCall`), sesión (persistida con `shared_preferences`), catálogo i18n
  (ES/EN), fechas, utilidades de código de invitación, widgets compartidos y
  providers de DI manual.
- `lib/features/<nombre>/` — por feature: `*_repository.dart` (datos),
  `*_controller.dart` (estado), `*_screen.dart` (UI), `*_models.dart` (dominio).

La gestión del estado y el i18n replican los patrones y el catálogo por claves
de la app de administrador para que ambos clientes se mantengan sincronizados.
Se eligió Riverpod para el flujo de Mercado Pago y las futuras notificaciones
por SMS/correo (diferidas hasta que el backend exponga los endpoints).

## Configuración

La URL base del backend se inyecta en tiempo de compilación y, por defecto,
apunta al backend desplegado:

```
flutter run --dart-define=API_BASE_URL=http://localhost:5211   # local
flutter run                                                     # usa la URL por defecto
```

## Compilación y pruebas

```
flutter pub get
flutter analyze      # 0 incidencias
flutter test         # pruebas unitarias de InviteCodes, ReservationRules e i18n
flutter build apk --debug
```

## Credenciales de prueba

- Admin: `admin@buildingfex.test` / cualquier contraseña (usar la app Compose).
- Residente: `residente@buildingfex.test`, código de invitación `301`,
  `ownerAdminId: admin-seed-1`.
