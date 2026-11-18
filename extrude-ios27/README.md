# Extrude — Process Manager for iOS 27.2

> **Inspirado en [Extrude](https://havoc.app/package/extrude) de hans32**
> Adaptado para jailbreak rootless en iOS 27.2

## Descripción

Extrude es un **Activity Monitor / Task Manager** para dispositivos iOS jailbroken. Permite visualizar, buscar, pausar, reanudar y matar procesos y daemons del sistema directamente desde una UI nativa con tema oscuro.

## Características

| Feature | Descripción |
|---------|-------------|
| 📋 **Lista de procesos** | Visualiza todos los procesos activos con PID, nombre, path y uso de memoria |
| 🔍 **Búsqueda** | Busca por nombre, PID o ruta del ejecutable |
| 🏷️ **Filtros** | All · User · System · Apps · Daemons |
| 📊 **Ordenar** | Por nombre, PID, memoria o CPU |
| ⏸️ **Pausar/Reanudar** | SIGSTOP/SIGCONT vía swipe o menú contextual |
| ❌ **Kill** | SIGKILL o SIGTERM con confirmación |
| 📋 **Copiar** | Copia nombre, PID o path al clipboard |
| 📂 **Filza** | Abre directamente la ruta del proceso en Filza |
| 🔄 **Auto-refresh** | Se actualiza cada 3 segundos |
| 📱 **Detalle** | Vista detallada con info de memoria, threads, Mach IPC, timing, etc. |
| 🌙 **Tema oscuro** | UI nativa con tema oscuro profesional |
| 👆 **Context menus** | Menús contextuales (long press) con todas las acciones |

## Estructura del proyecto

```
extrude-ios27/
├── Makefile                          # Build system (Theos, rootless)
├── control                           # Package metadata (dpkg)
├── entitlements.plist                # Entitlements para acceso a procesos
├── Resources/
│   └── Info.plist                    # Bundle metadata
└── Sources/
    ├── main.m                        # Entry point
    ├── EXAppDelegate.h/m             # App delegate, navigation setup
    ├── EXProcessInfo.h/m             # Modelo de datos de proceso
    ├── EXProcessManager.h/m          # Core: sysctl + libproc enumeration
    ├── EXProcessCell.h/m             # Celda personalizada con iconos
    ├── EXProcessListViewController.h/m  # Lista principal + búsqueda + filtros
    └── EXProcessDetailViewController.h/m # Vista detallada con acciones
```

## APIs utilizadas

| API | Uso |
|-----|-----|
| `sysctl(KERN_PROC_ALL)` | Enumerar todos los procesos |
| `proc_name()` | Obtener nombre del proceso |
| `proc_pidpath()` | Obtener ruta del ejecutable |
| `proc_pidinfo(PROC_PIDTASKINFO)` | Memoria residente, threads, Mach stats |
| `proc_pidinfo(PROC_PIDTBSDINFO)` | PPID, GID, start time, nice, flags |
| `kill(pid, signal)` | SIGKILL, SIGSTOP, SIGCONT, SIGTERM |

## Compilar

### Requisitos
- **Theos** instalado y configurado
- **iOS SDK** 15.0+
- Mac con Xcode Command Line Tools (o Linux con toolchain cross-compile)

### Build
```bash
cd extrude-ios27
make package THEOS_PACKAGE_SCHEME=rootless
```

### Instalar
```bash
make package install THEOS_DEVICE_IP=<ip-de-tu-dispositivo>
```

O copia el `.deb` generado en `packages/` y instálalo con tu gestor de paquetes favorito (Sileo, Zebra, etc.).

## Notas de compatibilidad iOS 27.2

> [!IMPORTANT]
> Este tweak está diseñado para entornos **rootless** (Dopamine, palera1n rootless, etc.).
> Todas las rutas usan el prefijo `/var/jb/`.

> [!WARNING]
> Matar procesos del sistema (SpringBoard, backboardd, etc.) puede causar inestabilidad o reinicio del dispositivo. Usa con precaución.

- Los entitlements incluyen `task_for_pid-allow` y `proc_info-allow` para acceso completo a la info de procesos
- `com.apple.private.security.no-sandbox` permite operación fuera del sandbox
- Se instala en `/var/jb/Applications/Extrude.app`
- El `uicache` post-instalación registra el icono en SpringBoard

## Personalización

Puedes ajustar:
- **Intervalo de refresh**: Cambia `3.0` en `viewWillAppear:` del `EXProcessListViewController`
- **Colores del tema**: Los colores están hardcoded como `UIColor` calls en cada archivo de UI
- **Filtros de daemons**: Ajusta las rutas en `processesFilteredBy:` del `EXProcessManager`
- **Bundle ID**: Cambia `com.yourname.extrude` en `control` e `Info.plist`
