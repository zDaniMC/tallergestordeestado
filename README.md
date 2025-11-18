# 📱 To-Do Offline Sync App

Una aplicación Flutter robusta con arquitectura limpia, sincronización offline-first y persistencia local usando SQLite.

## 🎯 Características

- ✅ **CRUD completo** de tareas (Crear, Leer, Actualizar, Eliminar)
- 📱 **Offline-first**: Funciona sin conexión a internet
- 🔄 **Sincronización automática** cuando se recupera la conexión
- 💾 **Persistencia local** con SQLite (`sqflite`)
- 🏗️ **Arquitectura limpia** con separación de capas
- 🎨 **Material Design 3** con UI moderna
- 🔍 **Filtros** (Todas, Pendientes, Completadas)
- ⏱️ **Cola de operaciones** con reintentos exponenciales
- 🌐 **Gestión de estado** con Riverpod

## 🏗️ Arquitectura

```
lib/
├── core/                        # Utilidades y configuración
│   ├── network/
│   │   └── connectivity_service.dart    # Monitoreo de conectividad
│   └── database/
│       └── database_helper.dart         # Configuración SQLite
│
├── data/                        # Capa de datos
│   ├── models/
│   │   └── task_model.dart             # Modelos y conversiones
│   ├── local/
│   │   ├── task_local_datasource.dart  # Persistencia local
│   │   └── queue_local_datasource.dart # Cola de sincronización
│   ├── remote/
│   │   └── task_remote_datasource.dart # API REST
│   └── repositories/
│       └── task_repository_impl.dart   # Implementación del repositorio
│
├── domain/                      # Capa de dominio
│   ├── entities/
│   │   └── task.dart                   # Entidad de negocio
│   └── repositories/
│       └── task_repository.dart        # Interfaz del repositorio
│
├── presentation/                # Capa de presentación
│   ├── providers/
│   │   └── providers.dart              # Gestión de estado (Riverpod)
│   ├── screens/
│   │   └── task_list_screen.dart       # Pantalla principal
│   └── widgets/
│       └── task_item.dart              # Widget de tarea
│
└── main.dart                    # Punto de entrada
```

## 🛠️ Tecnologías

- **Flutter 3.x**
- **Riverpod** - Gestión de estado
- **sqflite** - Base de datos SQLite
- **connectivity_plus** - Detección de conectividad
- **http** - Cliente HTTP
- **uuid** - Generación de IDs únicos
- **intl** - Formateo de fechas

## 📦 Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/todo-offline-sync.git
cd todo-offline-sync
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar el backend (json-server)

**Instalar json-server:**
```bash
npm install -g json-server
```

**Crear el archivo `db.json` en la raíz del proyecto:**
```json
{
  "tasks": []
}
```

**Iniciar el servidor:**
```bash
json-server --watch db.json --port 3000
```

### 4. Configurar la URL de la API

Editar `lib/presentation/providers/providers.dart`:

```dart
// Para emulador Android
const apiUrl = 'http://10.0.2.2:3000';

// Para dispositivo físico (usar IP de tu computadora)
const apiUrl = 'http://192.168.1.X:3000';

// Para iOS simulator
const apiUrl = 'http://localhost:3000';
```

### 5. Ejecutar la aplicación

```bash
flutter run
```

## 📱 Generar APK

### APK de depuración
```bash
flutter build apk --debug
```

### APK de producción
```bash
flutter clean
flutter pub get
flutter build apk --release
```

El APK se encuentra en: `build/app/outputs/flutter-apk/app-release.apk`

## 🧪 Probar el modo Offline

### Escenario 1: Crear tareas sin conexión

1. **Desactivar WiFi/Datos** en el dispositivo
2. **Crear varias tareas** en la app
3. Observar el indicador naranja mostrando operaciones pendientes
4. **Reactivar la conexión**
5. La app sincronizará automáticamente y el indicador se pondrá verde

### Escenario 2: Editar tareas sin conexión

1. **Desactivar la conexión**
2. **Modificar tareas existentes** (marcar como completadas, editar títulos)
3. Las operaciones se encolarán localmente
4. **Reconectar** y verificar que los cambios se sincronicen

### Escenario 3: Eliminar tareas sin conexión

1. **Desactivar la conexión**
2. **Eliminar tareas**
3. Las tareas se marcan como eliminadas localmente
4. **Reconectar** y las tareas se eliminarán del servidor

### Escenario 4: Resolución de conflictos (Last-Write-Wins)

1. **Modificar una tarea en la app** sin conexión
2. **Modificar la misma tarea en el servidor** (via json-server)
3. **Reconectar la app**
4. La versión más reciente (según `updatedAt`) prevalecerá

## 🔄 Flujo de Sincronización

```
1. Usuario realiza acción (crear/editar/eliminar)
   ↓
2. Cambio se guarda INMEDIATAMENTE en SQLite
   ↓
3. Operación se encola en queue_operations
   ↓
4. Si hay conexión:
   - Intenta sincronizar con el servidor
   - Si éxito: marca como synced_at
   - Si falla: incrementa attempt_count
   ↓
5. Reintentos con backoff exponencial
   ↓
6. Máximo 5 intentos, luego se descarta
```

## 🗄️ Esquema de Base de Datos

### Tabla `tasks`
```sql
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  completed INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL,
  synced_at TEXT,
  deleted INTEGER NOT NULL DEFAULT 0
);
```

### Tabla `queue_operations`
```sql
CREATE TABLE queue_operations (
  id TEXT PRIMARY KEY,
  entity TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  op TEXT NOT NULL,
  payload TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  completed INTEGER NOT NULL DEFAULT 0
);
```

## 🎨 Capturas de Pantalla

### Pantalla Principal
- Lista de tareas con indicadores de sincronización
- Filtros (Todas/Pendientes/Completadas)
- Pull-to-refresh para sincronizar manualmente

### Indicadores de Estado
- 🟢 **Verde**: Tarea sincronizada con el servidor
- 🟠 **Naranja**: Operación pendiente de sincronización
- 🔴 **Rojo**: Error de sincronización

## 🔧 Troubleshooting

### Error: "Connection refused"
- Verificar que json-server esté corriendo
- Verificar la URL de la API en `providers.dart`
- Para emulador Android usar `10.0.2.2` en lugar de `localhost`

### Las tareas no se sincronizan
- Verificar conectividad de red
- Revisar logs en la consola
- Verificar que el backend esté respondiendo correctamente

### Base de datos corrupta
```dart
// Limpiar la base de datos (solo para desarrollo)
await DatabaseHelper().deleteDatabase();
```

## 📝 Buenas Prácticas Implementadas

- ✅ **Separation of Concerns**: Capas domain/data/presentation
- ✅ **Dependency Injection**: Uso de Providers
- ✅ **Error Handling**: Try-catch y manejo de excepciones
- ✅ **Idempotency**: Uso de Idempotency-Key en requests
- ✅ **Soft Delete**: Las tareas no se eliminan hasta sincronizar
- ✅ **Conflict Resolution**: Last-Write-Wins basado en timestamp
- ✅ **Retry Logic**: Backoff exponencial para reintentos
- ✅ **Clean Code**: Código documentado y bien estructurado

