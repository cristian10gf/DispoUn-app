# Makefile para DispoUn App
# Facilita tareas comunes de desarrollo en Flutter

.PHONY: help deps generate watch run run-release run-profile build apk apk-split appbundle ios clean clean-all test analyze format icons doctor devices upgrade

# Colores para output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Configuracion
APP_NAME := dispoun_app
APK_PATH := build/app/outputs/flutter-apk
BUNDLE_PATH := build/app/outputs/bundle/release

#---------------------------------------
# Ayuda
#---------------------------------------

help: ## Muestra esta ayuda
	@echo ""
	@echo "$(BLUE)DispoUn App - Comandos disponibles$(NC)"
	@echo "======================================"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

#---------------------------------------
# Dependencias
#---------------------------------------

deps: ## Instala las dependencias del proyecto
	@echo "$(BLUE)Instalando dependencias...$(NC)"
	flutter pub get
	@echo "$(GREEN)Dependencias instaladas$(NC)"

upgrade: ## Actualiza las dependencias a la ultima version
	@echo "$(BLUE)Actualizando dependencias...$(NC)"
	flutter pub upgrade
	@echo "$(GREEN)Dependencias actualizadas$(NC)"

#---------------------------------------
# Generacion de codigo
#---------------------------------------

generate: ## Genera codigo con build_runner (modelos freezed, etc.)
	@echo "$(BLUE)Generando codigo...$(NC)"
	dart run build_runner build --delete-conflicting-outputs
	@echo "$(GREEN)Codigo generado$(NC)"

watch: ## Genera codigo en modo watch (regenera automaticamente al detectar cambios)
	@echo "$(BLUE)Iniciando build_runner en modo watch...$(NC)"
	dart run build_runner watch --delete-conflicting-outputs

#---------------------------------------
# Ejecucion
#---------------------------------------

run: ## Ejecuta la app en modo debug
	@echo "$(BLUE)Ejecutando en modo debug...$(NC)"
	flutter run

run-release: ## Ejecuta la app en modo release
	@echo "$(BLUE)Ejecutando en modo release...$(NC)"
	flutter run --release

run-profile: ## Ejecuta la app en modo profile (para analisis de rendimiento)
	@echo "$(BLUE)Ejecutando en modo profile...$(NC)"
	flutter run --profile

run-device: ## Ejecuta en un dispositivo especifico (usar con DEVICE=id)
	@echo "$(BLUE)Ejecutando en dispositivo $(DEVICE)...$(NC)"
	flutter run -d $(DEVICE)

#---------------------------------------
# Compilacion Android
#---------------------------------------

build: ## Compila APK de debug
	@echo "$(BLUE)Compilando APK de debug...$(NC)"
	flutter build apk --debug
	@echo "$(GREEN)APK de debug generado en: $(APK_PATH)/app-debug.apk$(NC)"

apk: ## Compila APK de release (optimizado)
	@echo "$(BLUE)Compilando APK de release...$(NC)"
	flutter build apk --release
	@echo "$(GREEN)APK de release generado en: $(APK_PATH)/app-release.apk$(NC)"

apk-split: ## Compila APKs separados por arquitectura (arm64, armeabi, x86_64)
	@echo "$(BLUE)Compilando APKs por ABI...$(NC)"
	flutter build apk --split-per-abi --release
	@echo "$(GREEN)APKs generados en: $(APK_PATH)/$(NC)"
	@ls -la $(APK_PATH)/*.apk 2>/dev/null || true

appbundle: ## Compila App Bundle para Google Play Store
	@echo "$(BLUE)Compilando App Bundle...$(NC)"
	flutter build appbundle --release
	@echo "$(GREEN)App Bundle generado en: $(BUNDLE_PATH)/app-release.aab$(NC)"

#---------------------------------------
# Compilacion iOS (solo macOS)
#---------------------------------------

ios: ## Compila para iOS (requiere macOS y Xcode)
	@echo "$(BLUE)Compilando para iOS...$(NC)"
	flutter build ios --release
	@echo "$(GREEN)Build de iOS completado$(NC)"

ios-simulator: ## Compila para simulador de iOS
	@echo "$(BLUE)Compilando para simulador iOS...$(NC)"
	flutter build ios --simulator
	@echo "$(GREEN)Build para simulador completado$(NC)"

#---------------------------------------
# Limpieza
#---------------------------------------

clean: ## Limpia archivos de build
	@echo "$(BLUE)Limpiando archivos de build...$(NC)"
	flutter clean
	@echo "$(GREEN)Limpieza completada$(NC)"

clean-all: clean ## Limpia todo incluyendo codigo generado y cache
	@echo "$(BLUE)Limpiando codigo generado...$(NC)"
	find . -name "*.g.dart" -type f -delete
	find . -name "*.freezed.dart" -type f -delete
	rm -rf .dart_tool/
	@echo "$(GREEN)Limpieza completa realizada$(NC)"

#---------------------------------------
# Testing y Analisis
#---------------------------------------

test: ## Ejecuta todos los tests
	@echo "$(BLUE)Ejecutando tests...$(NC)"
	flutter test
	@echo "$(GREEN)Tests completados$(NC)"

test-coverage: ## Ejecuta tests con reporte de cobertura
	@echo "$(BLUE)Ejecutando tests con cobertura...$(NC)"
	flutter test --coverage
	@echo "$(GREEN)Reporte de cobertura generado en: coverage/lcov.info$(NC)"

analyze: ## Analiza el codigo con el linter
	@echo "$(BLUE)Analizando codigo...$(NC)"
	flutter analyze
	@echo "$(GREEN)Analisis completado$(NC)"

format: ## Formatea todo el codigo Dart
	@echo "$(BLUE)Formateando codigo...$(NC)"
	dart format lib/ test/
	@echo "$(GREEN)Codigo formateado$(NC)"

format-check: ## Verifica el formato sin modificar archivos
	@echo "$(BLUE)Verificando formato...$(NC)"
	dart format --set-exit-if-changed lib/ test/

#---------------------------------------
# Utilidades
#---------------------------------------

icons: ## Genera los iconos de la app desde assets/logo.jpg
	@echo "$(BLUE)Generando iconos...$(NC)"
	dart run flutter_launcher_icons
	@echo "$(GREEN)Iconos generados$(NC)"

doctor: ## Verifica la instalacion de Flutter y dependencias
	@echo "$(BLUE)Verificando instalacion de Flutter...$(NC)"
	flutter doctor -v

devices: ## Lista los dispositivos conectados
	@echo "$(BLUE)Dispositivos disponibles:$(NC)"
	flutter devices

emulators: ## Lista los emuladores disponibles
	@echo "$(BLUE)Emuladores disponibles:$(NC)"
	flutter emulators

#---------------------------------------
# Flujos combinados
#---------------------------------------

setup: deps generate ## Configura el proyecto desde cero (deps + generate)
	@echo "$(GREEN)Proyecto configurado correctamente$(NC)"

rebuild: clean deps generate build ## Limpia y reconstruye todo
	@echo "$(GREEN)Proyecto reconstruido$(NC)"

release: clean deps generate apk ## Genera APK de release desde cero
	@echo "$(GREEN)APK de release listo para distribucion$(NC)"
	@echo "Ubicacion: $(APK_PATH)/app-release.apk"

ci: deps generate analyze test ## Pipeline de CI (deps, generate, analyze, test)
	@echo "$(GREEN)Pipeline de CI completado$(NC)"

#---------------------------------------
# Informacion del proyecto
#---------------------------------------

info: ## Muestra informacion del proyecto
	@echo ""
	@echo "$(BLUE)Informacion del proyecto$(NC)"
	@echo "========================="
	@echo "Nombre: $(APP_NAME)"
	@echo "Version de Flutter:"
	@flutter --version | head -1
	@echo ""
	@echo "Dependencias principales:"
	@grep -E "^\s+flutter_riverpod:|^\s+go_router:|^\s+freezed:" pubspec.yaml || true
	@echo ""

version: ## Muestra la version de Flutter y Dart
	@flutter --version
