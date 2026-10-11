#!/usr/bin/env python3
"""Gera o banco SQLite fictício usado nas capturas da App Store (uma loja online).

    python3 appstore/demo-db.py build/appstore/loja.sqlite

Dados determinísticos (semente fixa) e inventados — nenhum dado real.
"""
import random, sqlite3, sys, os
from datetime import date, timedelta

out = sys.argv[1]
os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
if os.path.exists(out): os.remove(out)
rnd = random.Random(42)

nomes = "Ana Bruno Carla Diego Eduarda Felipe Gabriela Henrique Isabela João Larissa Marcelo Natália Otávio Paula Rafael Sofia Thiago Valéria Wesley Beatriz Caio Daniela Enzo Fernanda Gustavo Helena Igor Júlia Lucas Mariana Nicolas Olívia Pedro Renata Samuel Tatiana Vinícius Yasmin".split()
sobrenomes = "Silva Santos Oliveira Souza Lima Pereira Costa Ferreira Almeida Ribeiro Carvalho Gomes Martins Rocha Barbosa Melo Araújo Cardoso Teixeira Moreira".split()
cidades = [("São Paulo","SP"),("Rio de Janeiro","RJ"),("Belo Horizonte","MG"),("Curitiba","PR"),("Porto Alegre","RS"),("Florianópolis","SC"),("Salvador","BA"),("Recife","PE"),("Fortaleza","CE"),("Brasília","DF"),("Goiânia","GO"),("Campinas","SP")]
peso_cidades = [30,18,10,8,7,6,5,5,4,4,2,3]
categorias = {
    "Surf": ["Prancha 6'2 Shortboard","Prancha 9'0 Longboard","Quilha FCS II","Leash 6 pés","Parafina Tropical","Deck antiderrapante","Capa de prancha"],
    "Roupas": ["Long john 3/2mm","Lycra UV manga longa","Bermuda boardshort","Camiseta Wave","Boné aba curva","Moletom Swell"],
    "Acessórios": ["Óculos polarizado","Relógio tábua de marés","Mochila estanque 20L","Toalha poncho","Garrafa térmica 750ml","Protetor solar FPS 50"],
    "Eletrônicos": ["Câmera de ação 4K","Fone Bluetooth à prova d'água","Caixa de som portátil","Carregador solar"],
}
db = sqlite3.connect(out)
db.executescript("""
PRAGMA foreign_keys = ON;
CREATE TABLE clientes (
  id INTEGER PRIMARY KEY,
  nome TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  cidade TEXT NOT NULL,
  uf TEXT NOT NULL,
  criado_em TEXT NOT NULL,
  ativo INTEGER NOT NULL DEFAULT 1
);
CREATE TABLE produtos (
  id INTEGER PRIMARY KEY,
  nome TEXT NOT NULL,
  categoria TEXT NOT NULL,
  preco REAL NOT NULL,
  estoque INTEGER NOT NULL
);
CREATE TABLE pedidos (
  id INTEGER PRIMARY KEY,
  cliente_id INTEGER NOT NULL REFERENCES clientes(id),
  status TEXT NOT NULL CHECK (status IN ('pago','enviado','entregue','cancelado')),
  total REAL NOT NULL,
  criado_em TEXT NOT NULL
);
CREATE TABLE itens_pedido (
  pedido_id INTEGER NOT NULL REFERENCES pedidos(id),
  produto_id INTEGER NOT NULL REFERENCES produtos(id),
  quantidade INTEGER NOT NULL,
  preco_unitario REAL NOT NULL,
  PRIMARY KEY (pedido_id, produto_id)
);
CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id);
CREATE INDEX idx_pedidos_status ON pedidos(status);
CREATE VIEW vendas_por_cidade AS
  SELECT c.cidade, COUNT(p.id) AS pedidos, ROUND(SUM(p.total), 2) AS receita
  FROM pedidos p JOIN clientes c ON c.id = p.cliente_id
  WHERE p.status <> 'cancelado'
  GROUP BY c.cidade;
""")
emails = set()
inicio = date(2024, 1, 1)
for i in range(1, 2501):
    nome = f"{rnd.choice(nomes)} {rnd.choice(sobrenomes)}"
    base = nome.lower().replace(" ", ".")
    for a, b in zip("áâãéêíóôõúç", "aaaeeiooouc"): base = base.replace(a, b)
    email = f"{base}@exemplo.com"
    n = 2
    while email in emails:
        email = f"{base}{n}@exemplo.com"; n += 1
    emails.add(email)
    cidade, uf = rnd.choices(cidades, peso_cidades)[0]
    db.execute("INSERT INTO clientes VALUES (?,?,?,?,?,?,?)",
               (i, nome, email, cidade, uf, (inicio + timedelta(days=rnd.randint(0, 600))).isoformat(), 0 if rnd.random() < 0.08 else 1))
pid = 0
precos = {}
for cat, itens in categorias.items():
    for nome in itens:
        pid += 1
        if "Prancha" in nome: faixa = (1490, 3290)
        elif cat == "Eletrônicos": faixa = (189, 1890)
        else: faixa = (29, 390)
        preco = round(rnd.uniform(*faixa), 2)
        precos[pid] = preco
        db.execute("INSERT INTO produtos VALUES (?,?,?,?,?)", (pid, nome, cat, preco, rnd.randint(0, 180)))
for i in range(1, 12001):
    itens = rnd.sample(list(precos), rnd.choices([1, 2, 3], [60, 30, 10])[0])
    linhas = [(p, rnd.choices([1, 2], [85, 15])[0]) for p in itens]
    total = round(sum(precos[p] * q for p, q in linhas), 2)
    status = rnd.choices(["pago", "enviado", "entregue", "cancelado"], [15, 20, 58, 7])[0]
    quando = inicio + timedelta(days=rnd.randint(30, 640), minutes=rnd.randint(0, 1439))
    db.execute("INSERT INTO pedidos VALUES (?,?,?,?,?)", (i, rnd.randint(1, 2500), status, total, quando.isoformat()))
    db.executemany("INSERT INTO itens_pedido VALUES (?,?,?,?)", [(i, p, q, precos[p]) for p, q in linhas])
db.commit()
db.execute("VACUUM")
db.close()
print(out)
