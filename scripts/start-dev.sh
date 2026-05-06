#!/bin/bash

# Script de inicio rápido para desarrollo local
echo "🚀 Iniciando Enmask - Plataforma de Data Masking"
echo ""

# Verificar si Docker está disponible
if ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado. Instálalo desde https://docker.com"
    exit 1
fi

# Iniciar base de datos si no está corriendo
if ! docker ps | grep -q postgres-dev; then
    echo "📦 Iniciando base de datos PostgreSQL local..."
    docker run --name postgres-dev -e POSTGRES_PASSWORD=mypassword -e POSTGRES_DB=testdb -e POSTGRES_USER=postgres -p 5432:5432 -d postgres:13 > /dev/null 2>&1
    echo "⏳ Esperando que la base de datos esté lista..."
    sleep 5
else
    echo "✅ Base de datos PostgreSQL ya está corriendo"
fi

# Verificar conexión a la base de datos
echo "🔍 Probando conexión a la base de datos..."
cd backend
python -c "
import asyncio
from app.infrastructure.db.postgres_client import PostgresClient

async def test():
    dsn = 'postgresql+asyncpg://postgres:mypassword@localhost:5432/testdb'
    try:
        client = PostgresClient(dsn)
        schema = await client.get_schema()
        print('✅ Base de datos conectada correctamente')
        return True
    except Exception as e:
        print(f'❌ Error conectando a la base de datos: {e}')
        return False

result = asyncio.run(test())
" 2>/dev/null

if [ "$result" = "False" ]; then
    echo "❌ No se pudo conectar a la base de datos. Revisa que Docker esté funcionando."
    exit 1
fi

# Instalar dependencias del backend si no están
if [ ! -d ".venv" ]; then
    echo "📦 Instalando dependencias del backend..."
    python -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt > /dev/null 2>&1
else
    source .venv/bin/activate
fi

# Instalar dependencias del frontend si no están
cd ../frontend
if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependencias del frontend..."
    npm install > /dev/null 2>&1
fi

echo ""
echo "🎉 Todo listo!"
echo ""
echo "Para iniciar la aplicación:"
echo "1. Backend: cd backend && source .venv/bin/activate && uvicorn app.main:app --reload --port 8000"
echo "2. Frontend: cd frontend && npm run dev"
echo ""
echo "Luego abre: http://localhost:5173"
echo ""
echo "Base de datos local:"
echo "  Host: localhost:5432"
echo "  Database: testdb"
echo "  User: postgres"
echo "  Password: mypassword"
echo ""
echo "Para detener la base de datos: ./scripts/db-local.sh stop"