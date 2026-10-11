# App Store Connect — TableSurf

Textos para colar no App Store Connect. Idioma principal: **Português (Brasil)**
(a interface do app é em português).

## Registro do app

| Campo | Valor |
| --- | --- |
| Plataformas | iOS e macOS (mesmo registro — compra universal) |
| Nome | `TableSurf` (se recusado: `TableSurf – SQL Client`) |
| Bundle ID | `dev.tablesurf.app` |
| SKU | `tablesurf` |
| Categoria principal | Ferramentas de desenvolvedor (Developer Tools) |
| Categoria secundária | Produtividade |
| Classificação etária | 4+ (nenhum conteúdo marcado) |
| URL de suporte | https://github.com/wagnerfnds/TableSurf/issues |
| URL de marketing | https://github.com/wagnerfnds/TableSurf |
| Política de privacidade | https://github.com/wagnerfnds/TableSurf/blob/main/PRIVACY.md |
| Privacidade do app | **Dados não coletados** |
| Criptografia | Só a padrão do sistema (TLS) — `ITSAppUsesNonExemptEncryption = NO` já está no Info.plist |
| Copyright | 2026 Wagner Fernandes |

## Português (Brasil)

**Subtítulo** (30): `PostgreSQL, MySQL e SQLite`

**Texto promocional** (170):
> Navegue por tabelas com milhões de linhas, edite dados com um toque e rode SQL com autocomplete — no iPhone, no iPad e no Mac.

**Palavras-chave** (100):
`sql,postgres,postgresql,mysql,mariadb,sqlite,banco de dados,database,query,cliente,tabela,dba`

**Descrição**:
```
TableSurf é um cliente de banco de dados nativo, rápido e leve para PostgreSQL, MySQL/MariaDB e SQLite. O mesmo app no iPhone, no iPad e no Mac.

DADOS SEM ESPERA
• Grade feita para tabelas grandes: só as células visíveis existem e a próxima página carrega enquanto você rola — a página 50 custa o mesmo que a primeira.
• Cabeçalho e números de linha fixos, ordenação tocando na coluna, puxar para atualizar.
• Filtros como chips removíveis; toque e segure numa célula para filtrar por aquele valor.

EDITE COM CONFIANÇA
• Toque numa célula para abrir a linha inteira como formulário: editar, definir NULL, seguir chaves estrangeiras e navegar entre linhas.
• Copie valores ou a linha como INSERT.
• Estrutura da tabela: colunas, índices, relações e triggers, com o DDL completo.

CONSOLE SQL DE VERDADE
• Realce de sintaxe e autocomplete de tabelas e colunas.
• Teclas de SQL acima do teclado no iPhone e iPad.
• Execute a seleção, o comando sob o cursor ou o script inteiro; cancele consultas longas.
• Histórico e consultas salvas.

IMPORTAR E EXPORTAR
• Exporte resultados em CSV, JSON ou SQL.
• Dumps e importação de arquivos .sql com progresso.
• Abra arquivos SQLite pelo app Arquivos ou pelo Finder.

NO MAC
• Abas, divisão de tela e paleta de comandos.
• Túneis SSH pelo ssh do sistema (agente, chave privada ou senha).

NO IPAD
• Layout em três colunas (conexões › tabelas › conteúdo) e atalhos de teclado.

PRIVACIDADE
• Senhas guardadas no Keychain. Nenhum dado coletado, sem rastreamento, sem contas.
• O app conecta direto aos seus servidores — nada passa por terceiros.
```

**Novidades desta versão**:
```
Primeira versão na App Store.
```

## English (U.S.) — opcional

**Subtitle**: `PostgreSQL, MySQL & SQLite`

**Promotional text**:
> Browse tables with millions of rows, edit data with a tap and run SQL with autocomplete — on iPhone, iPad and Mac.

**Keywords**: `sql,postgres,postgresql,mysql,mariadb,sqlite,database,query,client,table,dba,editor`

**Description**:
```
TableSurf is a fast, lightweight native database client for PostgreSQL, MySQL/MariaDB and SQLite — the same app on iPhone, iPad and Mac. (The interface is in Portuguese.)

• A data grid built for large tables: only visible cells exist and the next page loads as you scroll.
• Tap a cell to open the whole row as a form: edit, set NULL, follow foreign keys.
• Filters as removable chips; touch and hold a cell to filter by its value.
• Table structure: columns, indexes, relations, triggers and full DDL.
• SQL console with syntax highlighting, autocomplete, SQL keys above the keyboard, history and saved queries.
• Export to CSV, JSON or SQL; SQL dumps and imports with progress.
• Mac: tabs, split view, command palette and SSH tunnels through the system ssh.
• iPad: three-column layout and keyboard shortcuts.
• Passwords in the Keychain. No data collected, no tracking, no accounts.
```

## Notas para a revisão (App Review Information)

Login: **não é necessário** (desmarcar "Sign-in required").

```
TableSurf is a database client: it connects to database servers the user already has. No account or sign-in exists.

Quickest way to test (no server needed):
1. Tap "+" › "Nova conexão", choose "SQLite".
2. Tap "Criar banco vazio…", give it a name and save the connection.
3. Open it, tap "Console SQL" and run, for example:
   CREATE TABLE t (id INTEGER PRIMARY KEY, nome TEXT);
   INSERT INTO t (nome) VALUES ('a'), ('b');
   SELECT * FROM t;

To test a remote server, this public read-only PostgreSQL database (RNAcentral, EMBL-EBI) works:
  Host: hh-pgsql-public.ebi.ac.uk   Port: 5432
  Database: pfmegrnargs   User: reader   Password: NWDMCE5xdipIjRrp

On iOS, SSH tunnels are not available (they rely on the system ssh on the Mac).
```

## Capturas

Geradas por `appstore/screenshots.sh` (iPhone 6,9" e iPad 13") e
`appstore/screenshots-mac.sh` (Mac), com dados inventados de `appstore/demo-db.py`.
Ficam em `build/appstore/screenshots/` (fora do git).
