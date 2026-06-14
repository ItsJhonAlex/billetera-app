# Billetera

App Android de presupuesto personal, **offline-first**. Registra gastos, ingresos
y transferencias entre tus cuentas. Estética de cartera de cuero oscuro.

> MVP: cuentas, movimientos y categorías. Próximas iteraciones: presupuestos por
> categoría, gráficos y backup. La app se actualiza **sin perder datos** gracias a
> migraciones versionadas de la base de datos.

## Arquitectura

Capas desacopladas (fáciles de depurar, testear y escalar):

- `lib/domain/` — modelos y lógica pura (saldos, validación). Sin Flutter ni Drift.
- `lib/data/` — Drift/SQLite: tablas, DAOs, repositorio y siembra inicial.
- `lib/presentation/` — pantallas y widgets; estado con Riverpod.
- `lib/core/` — tema, formato de dinero y utilidades.

El dinero se guarda como entero en centavos (sin errores de `double`). Los saldos
se **calculan**, nunca se almacenan, así nunca se descuadran.

## Desarrollo

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # genera código Drift
flutter test
flutter run --flavor dev                                   # versión de desarrollo
```

### Flavors

Dos variantes que **conviven en el mismo dispositivo**:

| Flavor | applicationId                 | Nombre         |
|--------|-------------------------------|----------------|
| `dev`  | `es.itsjhonalex.billetera.dev`| Billetera Dev  |
| `prod` | `es.itsjhonalex.billetera`    | Billetera      |

```bash
flutter run   --flavor dev                       # desarrollo (flutter run)
flutter build apk --flavor prod --release --no-tree-shake-icons
```

> `--no-tree-shake-icons` es necesario porque los iconos de las categorías se
> eligen dinámicamente (codepoints guardados en la base de datos).

## Releases (GitHub Actions)

Al hacer push de un tag `v*` se compila el APK de producción y se adjunta a una
Release de GitHub:

```bash
git tag v0.0.1
git push origin v0.0.1
```

### Firma para actualizaciones

Para que las **actualizaciones** se instalen encima sin desinstalar, todas las
releases deben firmarse con el **mismo** keystore. Crea uno una vez:

```bash
keytool -genkey -v -keystore billetera.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias billetera
```

Y configura estos *secrets* en el repositorio (Settings → Secrets → Actions):

- `BILLETERA_KEYSTORE_BASE64` — el `.jks` en base64 (`base64 -w0 billetera.jks`).
- `BILLETERA_STORE_PASSWORD`, `BILLETERA_KEY_ALIAS`, `BILLETERA_KEY_PASSWORD`.

Sin estos secrets, el workflow compila igual pero con firma debug (las
actualizaciones requerirían desinstalar primero).
