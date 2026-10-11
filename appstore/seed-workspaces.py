#!/usr/bin/env python3
"""Conexões de exemplo das capturas. Hosts e nomes fictícios (domínio exemplo.com)."""
import json, sys, uuid

def conn(name, engine, color, host="", port=0, user="", database="", sqlite=""):
    return {"id": str(uuid.uuid5(uuid.NAMESPACE_URL, name)).upper(), "name": name, "engine": engine,
            "host": host, "port": port, "username": user, "password": "", "database": database,
            "sqlitePath": sqlite, "useTLS": engine != "sqlite", "color": color}

workspaces = [
    {"id": str(uuid.uuid5(uuid.NAMESPACE_URL, "ws-loja")).upper(), "name": "Loja online", "connections": [
        conn("Loja (demo)", "sqlite", "blue", sqlite=sys.argv[2] if len(sys.argv) > 2 else "loja.sqlite"),
        conn("Produção", "postgres", "red", "db.exemplo.com", 5432, "app", "loja"),
        conn("Staging", "postgres", "orange", "staging.exemplo.com", 5432, "app", "loja"),
    ]},
    {"id": str(uuid.uuid5(uuid.NAMESPACE_URL, "ws-dados")).upper(), "name": "Dados", "connections": [
        conn("Analytics", "mysql", "green", "analytics.exemplo.com", 3306, "leitura", "eventos"),
        conn("Blog", "mysql", "purple", "blog.exemplo.com", 3306, "wordpress", "blog"),
    ]},
]
json.dump(workspaces, open(sys.argv[1], "w"), ensure_ascii=False, indent=2)
