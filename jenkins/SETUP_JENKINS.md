# Configuracion de Jenkins para CryptoExchange Flutter

## Opcion 1: Jenkins con Docker (Recomendado)

### Paso 1 - Levantar Jenkins
```bash
cd jenkins
docker-compose up -d
```

### Paso 2 - Obtener password inicial
```bash
docker exec jenkins-flutter cat /var/jenkins_home/secrets/initialAdminPassword
```

### Paso 3 - Configurar Jenkins
1. Abrir http://localhost:8080
2. Pegar el password inicial
3. Instalar plugins sugeridos

### Paso 4 - Instalar plugins adicionales
Ir a **Manage Jenkins > Plugins > Available** e instalar:
- **Flutter SDK Plugin** (para manejar versiones de Flutter)
- **Pipeline** (ya viene instalado normalmente)
- **Git** (ya viene instalado normalmente)
- **JUnit** (para reportes de tests)

### Paso 5 - Configurar Flutter SDK
1. Ir a **Manage Jenkins > Tools**
2. En **Flutter SDK**, click **Add Flutter SDK**
3. Nombre: `Flutter SDK`
4. Instalar automaticamente, version: `stable`

### Paso 6 - Crear Pipeline
1. Click **New Item**
2. Nombre: `CryptoExchange`
3. Tipo: **Pipeline**
4. En Pipeline config:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `https://github.com/TU_USUARIO/TU_REPO.git`
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
5. Guardar

---

## Opcion 2: Jenkins instalado localmente (Windows)

### Paso 1 - Descargar Jenkins
- Descargar de https://www.jenkins.io/download/
- Instalar el .msi para Windows

### Paso 2 - Configurar Flutter en Jenkins
1. Ir a **Manage Jenkins > Tools**
2. Agregar Flutter SDK apuntando a tu instalacion local
   - Ejemplo: `C:\flutter` o donde tengas Flutter instalado

### Paso 3 - Crear Pipeline
Igual que Opcion 1, Paso 6.

---

## Que hace el Pipeline (Jenkinsfile)

```
Checkout → Flutter Doctor → Install Deps → Analyze → Unit Tests → Widget Tests → Coverage → Build APK
```

| Stage | Que hace |
|-------|----------|
| Checkout | Descarga el codigo del repo |
| Flutter Doctor | Verifica que Flutter esta bien configurado |
| Install Dependencies | Ejecuta `flutter pub get` |
| Analyze | Busca errores estaticos en el codigo |
| Unit Tests | Corre tests de models, services, providers |
| Widget Tests | Corre tests de widgets/UI |
| All Tests with Coverage | Genera reporte de cobertura |
| Build APK | Solo en branch `main`, genera el APK release |

## Trigger automatico (Webhook)

Para que Jenkins corra automaticamente al hacer push:

1. En Jenkins, ir al job > **Configure > Build Triggers**
2. Marcar **GitHub hook trigger for GITScm polling**
3. En GitHub, ir a **Settings > Webhooks > Add webhook**
   - URL: `http://TU_IP:8080/github-webhook/`
   - Content type: `application/json`
   - Evento: **Just the push event**
