/// ES/EN text catalog for the resident app.
///
/// Keys mirror the admin (Jetpack Compose) app 1:1 so both clients speak the
/// same language. Lookup order for a key: the localized side of the pair for
/// the active language, falling back to the other side, then to an optional
/// caller-supplied fallback.
library;

/// A localized pair: Spanish first, English second.
typedef TextPair = ({String es, String en});

class AppTexts {
  /// Active language code (`es` or `en`). Owned by `LanguageController`.
  static String lang = 'es';

  static void setLang(String value) => lang = value == 'en' ? 'en' : 'es';

  /// Resolves [key] in the active language, or null when unknown.
  static String? translateOrNull(String key) {
    final pair = _catalog[key];
    if (pair == null) return null;
    return lang == 'en' ? pair.en : pair.es;
  }

  /// Resolves [key], falling back to [fallback] then to the key itself.
  static String translate(String key, {String? fallback}) =>
      translateOrNull(key) ?? fallback ?? key;

  /// Resolves [key] and replaces `{placeholder}` occurrences with [params].
  static String format(String key, [Map<String, String> params = const {}]) {
    var text = translate(key);
    params.forEach((name, value) {
      text = text.replaceAll('{$name}', value);
    });
    return text;
  }
}

/// Shorthand for [AppTexts.translate] (resolves in the active language).
extension StringI18nX on String {
  String trText() => AppTexts.translate(this);

  String trFormat(Map<String, String> params) => AppTexts.format(this, params);
}

const Map<String, TextPair> _catalog = {
  // ---------------------------------------------------------------- errors
  'err.generic': (es: 'Ocurrió un error. Inténtalo nuevamente.', en: 'Something went wrong. Please try again.'),
  'err.NETWORK_ERROR': (es: 'Error de conexión. Comprueba tu red e inténtalo de nuevo.', en: 'Connection error. Check your network and try again.'),
  'err.TIMEOUT': (es: 'La solicitud tardó demasiado. Inténtalo de nuevo.', en: 'The request took too long. Try again.'),
  'err.SESSION_EXPIRED': (es: 'Tu sesión expiró. Inicia sesión de nuevo.', en: 'Your session expired. Sign in again.'),
  'err.HTTP_401': (es: 'Tu sesión expiró. Inicia sesión de nuevo.', en: 'Your session expired. Sign in again.'),
  'err.EMAIL_NOT_FOUND': (es: 'No encontramos una cuenta con este correo. Prueba con otro o regístrate.', en: "We couldn't find an account with this email. Try another one or sign up."),
  'err.INVALID_PASSWORD': (es: 'La contraseña es incorrecta.', en: 'The password is incorrect.'),
  'err.EMAIL_ALREADY_EXISTS': (es: 'Ya existe una cuenta con este correo.', en: 'An account with this email already exists.'),
  'err.AUTH_ERROR': (es: 'No se pudo completar la autenticación.', en: 'Sign-in could not be completed.'),
  'err.RESIDENT_LOGIN_BLOCKED': (es: 'Esta aplicación es para administradores. Ingresa con tu cuenta de administrador o usa la app de residentes.', en: 'This app is for administrators. Sign in with an administrator account or use the resident app.'),
  'err.ADMIN_LOGIN_BLOCKED': (es: 'Esta cuenta es de administrador. Usa la app de administradores de BuildingFex.', en: 'This account is an administrator. Use the BuildingFex admin app.'),
  'err.RESIDENT_FIELDS_REQUIRED': (es: 'Completa nombre y número de departamento para continuar.', en: 'Enter the name and department number to continue.'),
  'err.RESIDENT_CODE_ALREADY_EXISTS': (es: 'Ya existe un residente con ese número de departamento.', en: 'A resident with that department number already exists.'),
  'err.INVALID_DEPARTMENT_NUMBER': (es: 'Número de departamento inválido. Usa 3 o 4 dígitos (ej. 304 = piso 3).', en: 'Invalid department number. Use 3 or 4 digits (e.g. 304 = floor 3).'),
  'err.RESIDENT_NOT_FOUND': (es: 'No se encontró al residente.', en: 'Resident not found.'),
  'err.RESIDENT_OWNER_REQUIRED': (es: 'No pudimos identificar la cuenta administradora.', en: "We couldn't identify the administrator account."),
  'err.RESIDENT_PLAN_LIMIT_REACHED': (es: 'Límite del plan alcanzado (máximo de residentes). Cambia el plan en Ajustes si necesitas más.', en: 'Plan limit reached (maximum residents). Change your plan in Settings if you need more.'),
  'err.RESIDENT_DELETE_FAILED': (es: 'No se pudo eliminar al residente.', en: 'The resident could not be removed.'),
  'err.SPACE_NAME_REQUIRED': (es: 'Indica el nombre del espacio.', en: 'Enter the space name.'),
  'err.SPACE_NOT_FOUND': (es: 'No se encontró el espacio.', en: 'Space not found.'),
  'err.RESERVATION_FIELDS_REQUIRED': (es: 'Completa fecha, hora de inicio y hora de fin.', en: 'Enter the date, start time and end time.'),
  'err.RESERVATION_TIME_INVALID': (es: 'La hora de inicio debe ser anterior a la hora de fin.', en: 'The start time must be before the end time.'),
  'err.RESERVATION_OVERLAP': (es: 'Ese horario ya está ocupado. Elige otro rango.', en: 'That time slot is already taken. Choose another range.'),
  'err.RESERVATION_NOT_FOUND': (es: 'No se encontró la reserva.', en: 'Reservation not found.'),
  'err.GUEST_NOT_FOUND': (es: 'No se encontró al invitado.', en: 'Guest not found.'),
  'err.INVITE_NOT_FOUND': (es: 'Esta invitación ya no es válida o el residente no existe.', en: 'This invitation is no longer valid or the resident does not exist.'),
  'err.OWNER_REQUIRED': (es: 'No pudimos identificar la cuenta administradora.', en: "We couldn't identify the administrator account."),
  'err.SETTINGS_NOT_FOUND': (es: 'No se encontró la configuración financiera.', en: 'Financial settings not found.'),
  'err.SETTINGS_INVALID': (es: 'Monto base inválido.', en: 'Invalid base amount.'),
  'err.RECEIPT_ALREADY_PENDING': (es: 'Este residente ya tiene un recibo pendiente. Regístralo primero o espera a que pague.', en: 'This resident already has a pending receipt. Record it first or wait for them to pay.'),
  'err.INCIDENT_DESCRIPTION_REQUIRED': (es: 'Descripción requerida', en: 'Description required'),
  'err.ANNOUNCEMENT_FIELDS_REQUIRED': (es: 'Título y contenido requeridos', en: 'Title and content are required'),
  'err.MESSAGE_EMPTY': (es: 'Escribe un mensaje.', en: 'Type a message.'),
  'err.UNEXPECTED_ERROR': (es: 'Ocurrió un error. Inténtalo nuevamente.', en: 'Something went wrong. Please try again.'),
  'err.CONFIRM_FAILED': (es: 'No se pudo confirmar el pago. Si ya pagaste, espera unos minutos o contacta soporte.', en: 'The payment could not be confirmed. If you already paid, wait a few minutes or contact support.'),
  'err.CHECKOUT_ERROR': (es: 'No se pudo iniciar el pago con Mercado Pago. Inténtalo de nuevo.', en: 'The Mercado Pago checkout could not be started. Try again.'),
  'err.PAID_PLAN_REQUIRES_CHECKOUT': (es: 'No se pudo iniciar el pago con Mercado Pago.', en: 'The Mercado Pago checkout could not be started.'),
  'err.HTTP_400': (es: 'No se pudo procesar la solicitud. Revisa los datos.', en: 'The request could not be processed. Check the data.'),
  'err.HTTP_404': (es: 'El servidor no encontró ese recurso. Inténtalo más tarde.', en: 'The server could not find that resource. Try again later.'),
  'err.HTTP_409': (es: 'Ya existe un registro con esos datos.', en: 'A record with that data already exists.'),
  'err.HTTP_500': (es: 'Error interno del servidor. Inténtalo de nuevo.', en: 'Internal server error. Try again.'),
  'err.HTTP_502': (es: 'El servidor no responde. Inténtalo más tarde.', en: 'The server is not responding. Try again later.'),
  'err.HTTP_503': (es: 'El servidor no responde. Inténtalo más tarde.', en: 'The server is not responding. Try again later.'),
  'err.HTTP_504': (es: 'El servidor no responde. Inténtalo más tarde.', en: 'The server is not responding. Try again later.'),
  'err.HTTP_429': (es: 'Demasiados intentos. Espera un momento y vuelve a intentarlo.', en: 'Too many attempts. Wait a moment and try again.'),

  // ------------------------------------------------------------------ auth
  'auth.tagline.main': (es: 'Gestión inteligente de tu condominio', en: 'Smart management of your condominium'),
  'auth.tagline.invite': (es: 'Activación de cuenta de residente', en: 'Resident account activation'),
  'auth.tab.login': (es: 'Iniciar sesión', en: 'Sign in'),
  'auth.field.email': (es: 'Correo electrónico', en: 'Email'),
  'auth.field.password': (es: 'Contraseña', en: 'Password'),
  'auth.field.invite_code': (es: 'Código de invitación', en: 'Invitation code'),
  'auth.button.login': (es: 'Entrar', en: 'Sign in'),
  'auth.button.find_invite': (es: 'Buscar invitación', en: 'Find invitation'),
  'auth.button.access': (es: 'Acceder', en: 'Continue'),
  'auth.link.have_invite': (es: '¿Tienes un código de invitación? Activa tu cuenta', en: 'Have an invitation code? Activate your account'),
  'auth.link.back_to_login': (es: 'Volver a iniciar sesión', en: 'Back to sign in'),
  'auth.invite.placeholder': (es: 'Ej. 304-k7m2', en: 'E.g. 304-k7m2'),
  'auth.invite.supporting': (es: 'Pega el mensaje de invitación completo o escribe solo el código.', en: 'Paste the full invitation message or type just the code.'),
  'auth.invite.welcome': (es: 'Hola, te invitaron a unirte a este condominio', en: "Hi, you've been invited to join this condominium"),
  'auth.invite.data_ok': (es: 'Tus datos son correctos:', en: 'Your details are correct:'),
  'auth.invite.name': (es: 'Nombre: {name}', en: 'Name: {name}'),
  'auth.invite.code': (es: 'Código: {code}', en: 'Code: {code}'),
  'auth.invite.floor': (es: 'Piso: {floor}', en: 'Floor: {floor}'),
  'auth.invite.create_credentials': (es: 'Crea tus credenciales', en: 'Create your credentials'),
  'auth.invite.no_code': (es: 'No reconozco un código en el texto. Copia solo el código (ej. 304-k7m2).', en: "I can't find a code in the text. Copy just the code (e.g. 304-k7m2)."),
  'auth.error.invalid_email': (es: 'Introduce un correo electrónico válido.', en: 'Enter a valid email address.'),
  'auth.error.password_required': (es: 'Ingresa tu contraseña.', en: 'Enter your password.'),
  'auth.error.min_6': (es: 'Mínimo 6 caracteres.', en: 'At least 6 characters.'),
  'auth.error.invite_code_required': (es: 'Ingresa tu código de invitación.', en: 'Enter your invitation code.'),
  'auth.error.resident_not_found': (es: 'No encontramos residentes con el código "{code}". Revisa el mensaje de invitación.', en: 'We couldn\'t find any residents with the code "{code}". Check the invitation message.'),

  // ----------------------------------------------------------------- shell
  'shell.appName': (es: 'BuildingFex', en: 'BuildingFex'),
  'shell.language': (es: 'Idioma', en: 'Language'),
  'shell.logout': (es: 'Cerrar sesión', en: 'Log out'),
  'shell.openMenu': (es: 'Abrir menú', en: 'Open menu'),
  'shell.role.resident': (es: 'Residente', en: 'Resident'),
  'shell.nav.dashboard': (es: 'Dashboard', en: 'Dashboard'),
  'shell.nav.finances': (es: 'Finanzas', en: 'Finances'),
  'shell.nav.resident_services': (es: 'Espacios comunes', en: 'Common areas'),
  'shell.nav.myReservations': (es: 'Mis reservas', en: 'My bookings'),
  'shell.nav.incidents': (es: 'Incidencias', en: 'Incidents'),
  'shell.nav.support': (es: 'Soporte', en: 'Support'),
  'shell.nav.settings': (es: 'Ajustes', en: 'Settings'),

  // -------------------------------------------------------------- dashboard
  'dash.greeting': (es: 'Hola, {name}', en: 'Hello, {name}'),
  'dash.residentFallback': (es: 'residente', en: 'resident'),
  'dash.residentSubtitle': (es: 'Resumen de tu edificio.', en: 'Summary of your building.'),
  'dash.pendingBalance': (es: 'Saldo pendiente', en: 'Pending balance'),
  'dash.openIncidentsLabel': (es: 'Incidencias abiertas', en: 'Open incidents'),
  'dash.todayReservations': (es: 'Reservas hoy', en: 'Reservations today'),
  'dash.activeAnnouncements': (es: 'Comunicados activos', en: 'Active announcements'),
  'dash.paymentsTitle': (es: 'Estado de pagos', en: 'Payment status'),
  'dash.noFees': (es: 'Aún no tienes cuotas registradas.', en: "You don't have any registered fees yet."),
  'dash.slicePaid': (es: 'Pagado', en: 'Paid'),
  'dash.slicePending': (es: 'Pendiente', en: 'Pending'),
  'dash.sliceOverdue': (es: 'Vencido', en: 'Overdue'),
  'dash.overdueNotice': (es: 'Tienes {amount} vencidos.', en: 'You have {amount} overdue.'),
  'dash.incidentsTitle': (es: 'Incidencias', en: 'Incidents'),
  'dash.chipOpen': (es: 'Abiertas: {n}', en: 'Open: {n}'),
  'dash.chipInProgress': (es: 'En curso: {n}', en: 'In progress: {n}'),
  'dash.chipResolved': (es: 'Resueltas: {n}', en: 'Resolved: {n}'),
  'dash.upcomingReservations': (es: 'Próximas reservas', en: 'Upcoming reservations'),
  'dash.noUpcomingReservations': (es: 'No tienes reservas próximas.', en: 'You have no upcoming reservations.'),
  'dash.defaultSpace': (es: 'Espacio social', en: 'Social space'),
  'dash.today': (es: 'Hoy', en: 'Today'),
  'dash.announcementsTitle': (es: 'Comunicados', en: 'Announcements'),

  // ------------------------------------------------------------------ fins
  'rfin.title': (es: 'Finanzas', en: 'Finances'),
  'rfin.subtitle': (es: 'Aquí verás tus cuotas y estado de cuenta.', en: "Here you'll see your fees and account statement."),
  'rfin.understood': (es: 'Entendido', en: 'Got it'),
  'rfin.pending': (es: 'Monto pendiente', en: 'Amount due'),
  'rfin.paidTotal': (es: 'Total pagado', en: 'Total paid'),
  'rfin.fees.title': (es: 'Mis cuotas', en: 'My fees'),
  'rfin.fees.empty': (es: 'Sin cuotas registradas aún.', en: 'No fees registered yet.'),
  'rfin.fees.row': (es: '{month} · vence {date}', en: '{month} · due {date}'),
  'rfin.checkout.title': (es: 'Pago con Mercado Pago', en: 'Payment with Mercado Pago'),
  'rfin.checkout.subtitle': (es: 'Paga todas tus cuotas pendientes en un solo proceso seguro.', en: 'Pay all your pending fees in one secure process.'),
  'rfin.checkout.opening': (es: 'Abriendo Mercado Pago…', en: 'Opening Mercado Pago…'),
  'rfin.checkout.pay': (es: 'Pagar con Mercado Pago', en: 'Pay with Mercado Pago'),
  'rfin.history.title': (es: 'Historial de pagos', en: 'Payment history'),
  'rfin.history.empty': (es: 'Aún no tienes pagos registrados.', en: "You don't have any payments yet."),
  'rfin.payment.fallbackConcept': (es: 'Cuota', en: 'Fee'),
  'rfin.status.paid': (es: 'Pagado', en: 'Paid'),
  'rfin.status.pending': (es: 'Pendiente', en: 'Pending'),
  'rfin.concept.maintenance': (es: 'Mantenimiento', en: 'Maintenance'),
  'rfin.concept.fee': (es: 'Cuota mantenimiento', en: 'Maintenance fee'),
  'rfin.month.current': (es: 'Mes actual', en: 'Current month'),
  'rfin.msg.demoConfirmed': (es: 'Pago demo confirmado y registrado.', en: 'Demo payment confirmed and recorded.'),
  'rfin.msg.checkoutOpened': (es: 'Se abrió Mercado Pago. Regresa aquí y confirma el pago.', en: 'Mercado Pago opened. Come back here and confirm the payment.'),
  'rfin.msg.checkoutFailed': (es: 'No se pudo iniciar el pago.', en: 'The payment could not be started.'),
  'rfin.msg.itemsReconciled': (es: '{n} cuota(s) reconciliada(s).', en: '{n} fee(s) reconciled.'),
  'rfin.msg.reconcileSoon': (es: 'Tu pago será reconciliado en unos minutos.', en: 'Your payment will be reconciled in a few minutes.'),
  'rfin.msg.paymentConfirmed': (es: 'Pago confirmado. {suffix}', en: 'Payment confirmed. {suffix}'),
  'rfin.msg.paymentFailed': (es: 'El pago no se completó. Puedes intentarlo de nuevo.', en: 'The payment was not completed. You can try again.'),
  'rfin.msg.paymentUnderReview': (es: 'Tu pago está en revisión. Te avisaremos cuando se confirme.', en: "Your payment is under review. We'll notify you when it's confirmed."),

  // --------------------------------------------------------------- services
  'services.title': (es: 'Espacios comunes', en: 'Common areas'),
  'services.subtitle': (es: 'Consulta y reserva los espacios del edificio.', en: "Browse and reserve the building's spaces."),
  'services.availableTitle': (es: 'Espacios disponibles', en: 'Available spaces'),
  'services.empty': (es: 'No hay espacios publicados todavía.', en: 'There are no published spaces yet.'),
  'services.capacity': (es: 'Capacidad: {n}', en: 'Capacity: {n}'),
  'services.reserve': (es: 'Reservar', en: 'Reserve'),
  'services.reserveTitle': (es: 'Reservar {name}', en: 'Reserve {name}'),
  'services.confirmReserve': (es: 'Confirmar reserva', en: 'Confirm reservation'),
  'services.fieldDate': (es: 'Fecha', en: 'Date'),
  'services.fieldStart': (es: 'Inicio', en: 'Start'),
  'services.fieldEnd': (es: 'Fin', en: 'End'),
  'services.chooseTime': (es: 'Elegir hora', en: 'Pick a time'),
  'services.reservedSlots': (es: 'Horarios ya reservados:', en: 'Already booked slots:'),
  'services.understood': (es: 'Entendido', en: 'Got it'),
  'services.reservedMessage': (es: 'Reserva confirmada en {name}.', en: 'Reservation confirmed at {name}.'),

  // ------------------------------------------------------------ reservations
  'resv.title': (es: 'Mis reservas', en: 'My reservations'),
  'resv.subtitle': (es: 'Administra los invitados de tus reservas y comparte la invitación.', en: 'Manage the guests of your reservations and share the invitation.'),
  'resv.empty': (es: 'No tienes reservas todavía. Solicita una desde Espacios comunes.', en: 'You have no reservations yet. Request one from Common areas.'),
  'resv.spaceFallback': (es: 'Espacio', en: 'Space'),
  'resv.guests': (es: 'Invitados', en: 'Guests'),
  'resv.hide': (es: 'Ocultar', en: 'Hide'),
  'resv.editGuests': (es: 'Editar invitados', en: 'Edit guests'),
  'resv.noGuests': (es: 'Sin invitados registrados.', en: 'No guests registered.'),
  'resv.checkedIn': (es: 'Ingresó', en: 'Checked in'),
  'resv.notCheckedIn': (es: 'Sin ingresar', en: 'Not checked in'),
  'resv.inviteTitle': (es: 'Invitación de huéspedes', en: 'Guest invitation'),
  'resv.inviteExpired': (es: 'La invitación expiró. Edita los invitados para generarla de nuevo.', en: 'The invitation expired. Edit the guests to generate it again.'),
  'resv.inviteQrDesc': (es: 'Código QR de la invitación', en: 'QR code of the invitation'),
  'resv.shareQr': (es: 'Compartir QR', en: 'Share QR'),
  'resv.save': (es: 'Guardar', en: 'Save'),
  'resv.guestsHint': (es: 'Hasta {n} nombres. Los que queden en blanco no se guardan.', en: 'Up to {n} names. Blank ones are not saved.'),
  'resv.guestLabel': (es: 'Invitado {n}', en: 'Guest {n}'),
  'resv.understood': (es: 'Entendido', en: 'Got it'),
  'resv.shareChooser': (es: 'Compartir invitación', en: 'Share invitation'),
  'resv.guestsUpdated': (es: 'Invitados actualizados.', en: 'Guests updated.'),
  'resv.shareUrl': (es: 'BuildingFex · invitación de huéspedes: {url}', en: 'BuildingFex · guest invitation: {url}'),
  'resv.shareToken': (es: 'BuildingFex · invitación de huéspedes (token): {token}', en: 'BuildingFex · guest invitation (token): {token}'),

  // -------------------------------------------------------------- incidents
  'inc.status.open': (es: 'Abierta', en: 'Open'),
  'inc.status.in-progress': (es: 'En progreso', en: 'In progress'),
  'inc.status.resolved': (es: 'Resuelta', en: 'Resolved'),
  'inc.resident.title': (es: 'Mis incidencias', en: 'My incidents'),
  'inc.resident.subtitle': (es: 'Revisa y reporta incidencias asociadas a tu unidad.', en: 'Review and report incidents associated with your unit.'),
  'inc.resident.reportCard': (es: 'Reportar nueva incidencia', en: 'Report a new incident'),
  'inc.resident.listCard': (es: 'Mis incidencias reportadas', en: 'My reported incidents'),
  'inc.resident.empty': (es: 'No tienes incidencias registradas.', en: 'You have no registered incidents.'),
  'inc.field.description': (es: 'Descripción', en: 'Description'),
  'inc.field.descriptionPlaceholder': (es: 'Describe el problema…', en: 'Describe the problem…'),
  'inc.action.send': (es: 'Enviar incidencia', en: 'Send incident'),
  'inc.action.sending': (es: 'Enviando…', en: 'Sending…'),
  'inc.action.edit': (es: 'Editar', en: 'Edit'),
  'inc.action.delete': (es: 'Eliminar', en: 'Delete'),
  'inc.action.save': (es: 'Guardar', en: 'Save'),
  'inc.action.saving': (es: 'Guardando…', en: 'Saving…'),
  'inc.action.cancel': (es: 'Cancelar', en: 'Cancel'),
  'inc.editor.editTitle': (es: 'Editar incidencia', en: 'Edit incident'),
  'inc.delete.title': (es: 'Eliminar incidencia', en: 'Delete incident'),
  'inc.delete.message': (es: '¿Eliminar esta incidencia? Esta acción no se puede deshacer.', en: 'Delete this incident? This action cannot be undone.'),
  'inc.message.title': (es: 'Listo', en: 'Done'),
  'inc.message.ack': (es: 'Entendido', en: 'Got it'),
  'inc.msg.sent': (es: 'Incidencia enviada.', en: 'Incident sent.'),
  'inc.msg.updated': (es: 'Incidencia actualizada.', en: 'Incident updated.'),
  'inc.msg.deleted': (es: 'Incidencia eliminada.', en: 'Incident deleted.'),

  // --------------------------------------------------------------- support
  'sup.resident.title': (es: 'Soporte técnico', en: 'Technical support'),
  'sup.resident.subtitle': (es: 'Contacta al equipo de soporte de tu condominio.', en: "Contact your condominium's support team."),
  'sup.resident.empty': (es: 'Aún no tienes conversaciones de soporte.', en: "You don't have any support conversations yet."),
  'sup.faqs.title': (es: 'Preguntas frecuentes', en: 'Frequently asked questions'),
  'sup.chats.title': (es: 'Mis conversaciones', en: 'My conversations'),
  'sup.field.topic': (es: 'Tema de la conversación', en: 'Conversation topic'),
  'sup.field.messagePlaceholder': (es: 'Escribe un mensaje…', en: 'Type a message…'),
  'sup.action.newTicket': (es: 'Nuevo ticket de soporte', en: 'New support ticket'),
  'sup.action.opening': (es: 'Abriendo…', en: 'Opening…'),
  'sup.action.back': (es: 'Volver', en: 'Back'),
  'sup.action.send': (es: 'Enviar', en: 'Send'),
  'sup.dialog.title': (es: 'Soporte', en: 'Support'),
  'sup.dialog.ack': (es: 'Entendido', en: 'Got it'),
  'sup.chat.lastActivity': (es: 'Última actividad: {date} · {n} mensajes', en: 'Last activity: {date} · {n} messages'),
  'sup.chat.empty': (es: 'Aún no hay mensajes. Escribe el primero.', en: 'No messages yet. Write the first one.'),
  'sup.defaultTopic': (es: 'Soporte', en: 'Support'),
  'sup.faq.1.q': (es: '¿Cómo pago mi mantenimiento?', en: 'How do I pay my maintenance fee?'),
  'sup.faq.1.a': (es: 'Entra a Finanzas y usa el botón de pago con Mercado Pago. Al confirmar, tu cuota queda registrada al instante.', en: 'Go to Finances and use the Mercado Pago payment button. Once confirmed, your fee is recorded instantly.'),
  'sup.faq.2.q': (es: '¿Cómo reservo un espacio social?', en: 'How do I book a social space?'),
  'sup.faq.2.a': (es: 'Ve a Servicios, elige el espacio, selecciona fecha y horario y confirma la reserva. Verás tus reservas en Mis reservas.', en: "Go to Common areas, choose the space, select the date and time and confirm the booking. You'll see your bookings in My bookings."),
  'sup.faq.3.q': (es: '¿Cómo invito a un visitante?', en: 'How do I invite a visitor?'),
  'sup.faq.3.a': (es: 'En Mis reservas, agrega los invitados de tu reserva y comparte el enlace. El acceso caduca 25 minutos después del inicio.', en: "In My bookings, add your reservation's guests and share the link. Access expires 25 minutes after the start time."),
  'sup.faq.4.q': (es: '¿Cómo reporto una incidencia?', en: 'How do I report an incident?'),
  'sup.faq.4.a': (es: 'En Incidencias describe el problema y envíalo. El administrador dará seguimiento con el estado y el proveedor asignado.', en: 'In Incidents, describe the problem and send it. The administrator will track it with its status and assigned provider.'),

  // -------------------------------------------------------------- settings
  'set.title': (es: 'Ajustes', en: 'Settings'),
  'set.subtitle': (es: 'Tu perfil y la configuración de la app.', en: 'Your profile and the app settings.'),
  'set.profile.title': (es: 'Mi perfil', en: 'My profile'),
  'set.profile.loadFailed': (es: 'No se pudo cargar el perfil.', en: 'The profile could not be loaded.'),
  'set.profile.name': (es: 'Nombre', en: 'Name'),
  'set.profile.email': (es: 'Correo', en: 'Email'),
  'set.profile.department': (es: 'Departamento', en: 'Department'),
  'set.profile.floor': (es: 'Piso', en: 'Floor'),
  'set.profile.dni': (es: 'DNI', en: 'ID number'),
  'set.profile.address': (es: 'Dirección', en: 'Address'),
  'set.account.title': (es: 'Mi cuenta', en: 'My account'),
  'set.account.hint': (es: 'Actualiza tus datos personales o cambia tu contraseña. El correo no es editable.', en: 'Update your personal data or change your password. The email is not editable.'),
  'set.account.edit': (es: 'Editar mi cuenta', en: 'Edit my account'),
  'set.edit.title': (es: 'Editar cuenta', en: 'Edit account'),
  'set.edit.personal': (es: 'Datos personales', en: 'Personal data'),
  'set.edit.save': (es: 'Guardar cambios', en: 'Save changes'),
  'set.edit.saved': (es: 'Datos actualizados correctamente.', en: 'Data updated successfully.'),
  'set.edit.name_required': (es: 'El nombre es obligatorio.', en: 'The name is required.'),
  'set.edit.no_email': (es: 'Tu cuenta no tiene correo asociado; no se puede cambiar la contraseña.', en: 'Your account has no email; the password cannot be changed.'),
  'set.edit.password': (es: 'Cambiar contraseña', en: 'Change password'),
  'set.edit.new_password': (es: 'Nueva contraseña', en: 'New password'),
  'set.edit.confirm_password': (es: 'Confirmar contraseña', en: 'Confirm password'),
  'set.edit.password_hint': (es: 'Mínimo 6 caracteres.', en: 'At least 6 characters.'),
  'set.edit.show_password': (es: 'Mostrar contraseña', en: 'Show password'),
  'set.edit.change_password': (es: 'Actualizar contraseña', en: 'Update password'),
  'set.edit.password_mismatch': (es: 'Las contraseñas no coinciden.', en: 'The passwords do not match.'),
  'set.edit.password_changed': (es: 'Contraseña actualizada correctamente.', en: 'Password updated successfully.'),
  'set.edit.avatar': (es: 'Icono de perfil', en: 'Profile icon'),
  'set.edit.avatar_hint': (es: 'Elige un icono o usa una foto de tu galería.', en: 'Pick an icon or use a photo from your gallery.'),
  'set.edit.avatar_photo': (es: 'Usar foto de la galería', en: 'Use photo from gallery'),
  'set.edit.avatar_default': (es: 'Usar icono predeterminado', en: 'Use default icon'),
  'set.edit.avatar_photo_failed': (es: 'No se pudo cargar la foto. Intenta con otra imagen más pequeña.', en: 'The photo could not be loaded. Try a smaller image.'),
  'set.session.title': (es: 'Sesión', en: 'Session'),
  'set.session.logout': (es: 'Cerrar sesión', en: 'Log out'),
  'set.message.ack': (es: 'Entendido', en: 'Got it'),
};
