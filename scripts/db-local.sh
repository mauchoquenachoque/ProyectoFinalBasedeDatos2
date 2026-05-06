#!/bin/bash

# Script para manejar la base de datos PostgreSQL local
# Uso: ./db-local.sh [start|stop|restart|status|test]

case "$1" in
    start)
        echo "Iniciando base de datos PostgreSQL local..."
        docker run --name postgres-dev -e POSTGRES_PASSWORD=mypassword -e POSTGRES_DB=testdb -e POSTGRES_USER=postgres -p 5432:5432 -d postgres:13
        echo "Esperando que la base de datos esté lista..."
        sleep 5
        echo "Base de datos lista en localhost:5432"
        ;;
    stop)
        echo "Deteniendo base de datos PostgreSQL local..."
        docker stop postgres-dev
        docker rm postgres-dev
        ;;
    restart)
        echo "Reiniciando base de datos PostgreSQL local..."
        $0 stop
        sleep 2
        $0 start
        ;;
    status)
        echo "Estado de la base de datos:"
        docker ps | grep postgres-dev || echo "No está corriendo"
        ;;
    test)
        echo "Probando conexión a la base de datos local..."
        python -c "
import asyncio
from app.infrastructure.db.postgres_client import PostgresClient

async def test():
    dsn = 'postgresql+asyncpg://postgres:mypassword@localhost:5432/testdb'
    print(f'Probando conexión: {dsn}')
    try:
        client = PostgresClient(dsn)
        schema = await client.get_schema()
        print('✅ Conexión exitosa!')
        print(f'Tablas encontradas: {len(schema)}')
    except Exception as e:
        print(f'❌ Error: {e}')

asyncio.run(test())
        "
        ;;
    *)
        echo "Uso: $0 {start|stop|restart|status|test}"
        echo ""
        echo "Comandos:"
        echo "  start   - Inicia la base de datos"
        echo "  stop    - Detiene y elimina la base de datos"
        echo "  restart - Reinicia la base de datos"
        echo "  status  - Muestra el estado"
        echo "  test    - Prueba la conexión"
        ;;
esac