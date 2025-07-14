# Git Worktree Manager

Um gerenciador de worktrees Git que facilita a criação e gerenciamento de múltiplas árvores de trabalho para o mesmo repositório.

## O que é?

O Git Worktree Manager é um script bash que simplifica o trabalho com worktrees do Git. Ele permite criar, listar e remover worktrees de forma intuitiva, além de automatizar tarefas comuns como:

- Criação de branches e worktrees
- Cópia de arquivos de configuração (`.env`, `.cursor`, etc.)
- Cópia de `node_modules` para acelerar o desenvolvimento
- Abertura automática no Cursor IDE
- Navegação inteligente para manter o contexto do diretório atual

## Como instalar

### Usando o script install.sh

```bash
chmod +x install.sh
./install.sh
```

O script install.sh irá:

1. Baixar o script do repositório
2. Instalar em `~/.local/bin/worktree`
3. Tornar o script executável
4. Verificar se o diretório está no PATH

Se `~/.local/bin` não estiver no seu PATH, adicione esta linha ao seu `~/.bashrc` ou `~/.zshrc`:

```bash
export PATH="$PATH:~/.local/bin"
```

### Instalação manual

```bash
# Copiar o script para um diretório no PATH
cp worktree.sh ~/.local/bin/worktree
chmod +x ~/.local/bin/worktree
```

## Funcionalidades

### 1. Criar um novo worktree

Cria um novo worktree para uma feature branch.

```bash
worktree add my-new-feature
```

**O que faz:**

- Cria uma nova branch `my-new-feature` (se não existir)
- Cria um worktree em `../projeto-worktrees/my-new-feature`
- Copia arquivos de configuração (`.env`, `.cursor`, etc.)
- Copia `node_modules` do diretório atual
- Abre no Cursor IDE na mesma localização relativa

### 2. Criar worktree sem copiar node_modules

Para projetos grandes onde você prefere rodar `pnpm install` no novo worktree:

```bash
worktree add my-feature --skip-node-modules
```

### 3. Listar todos os worktrees

Mostra todos os worktrees existentes, destacando o atual com ★:

```bash
worktree list
```

**Exemplo de saída:**

```
=== Git Worktrees for meu-projeto ===

★ [current] [main repository] → main
   Path: /Users/usuario/projeto

Worktrees:
★ [current] ▸ feature-login
     /Users/usuario/projeto-worktrees/feature-login
  ▸ feature-dashboard → dashboard-improvements
     /Users/usuario/projeto-worktrees/feature-dashboard
```

### 4. Remover um worktree específico

Remove um worktree e limpa as referências:

```bash
worktree remove my-feature
```

**O que faz:**

- Remove o worktree do sistema de arquivos
- Limpa as referências Git
- Força a remoção mesmo com mudanças não commitadas

### 5. Remover todos os worktrees

Remove todos os worktrees com confirmação:

```bash
worktree remove-all
```

**O que faz:**

- Lista todos os worktrees que serão removidos
- Pede confirmação (y/N)
- Remove todos os worktrees sequencialmente

### 6. Ajuda

Mostra todas as opções disponíveis:

```bash
worktree --help
# ou
worktree -h
# ou simplesmente
worktree
```

## Estrutura de arquivos

O script organiza os worktrees da seguinte forma:

```
meu-projeto/                    # Repositório principal
│
├── src/
├── package.json
├── .env
└── ...

meu-projeto-worktrees/         # Diretório de worktrees
│
├── feature-login/             # Worktree para feature-login
│   ├── src/
│   ├── package.json
│   ├── .env                   # Copiado do principal
│   └── node_modules/          # Copiado do principal
│
└── feature-dashboard/         # Worktree para feature-dashboard
    ├── src/
    ├── package.json
    ├── .env                   # Copiado do principal
    └── node_modules/          # Copiado do principal
```

## Arquivos copiados automaticamente

O script copia automaticamente os seguintes arquivos e diretórios:

**Arquivos:**

- `.env`

**Diretórios:**

- `.instrumental`
- `.agent_os`
- `.claude`
- `.cursor`
- `node_modules` (pode ser pulado com `--skip-node-modules`)

## Requisitos

- Git
- Bash
- Cursor IDE (opcional, mas recomendado)
- Sistema operacional: macOS, Linux ou Windows com WSL

## Características especiais

### Copy-on-Write (COW)

No macOS com APFS, o script usa copy-on-write para copiar `node_modules` de forma mais eficiente, economizando espaço e tempo.

### Navegação inteligente

O script lembra onde você estava quando criou o worktree e abre o Cursor na mesma localização relativa no novo worktree.

### Detecção de branch existente

Se você criar um worktree para uma branch que já existe, o script usa a branch existente em vez de criar uma nova.

## Exemplos de uso

### Desenvolvimento de feature

```bash
# No diretório do projeto
cd ~/projetos/meu-app/src/components

# Criar worktree para nova feature
worktree add user-authentication

# O Cursor abre automaticamente em:
# ~/projetos/meu-app-worktrees/user-authentication/src/components
```

### Gerenciamento de múltiplas features

```bash
# Criar várias features
worktree add feature-login
worktree add feature-dashboard
worktree add bugfix-header

# Listar todas
worktree list

# Trabalhar em uma feature específica
cd ~/projetos/meu-app-worktrees/feature-login

# Remover feature concluída
worktree remove feature-login
```

### Limpeza de worktrees

```bash
# Remover todos os worktrees antigos
worktree remove-all

# Confirmar com 'y' quando perguntado
```

## Dicas de uso

1. **Use nomes descritivos** para seus worktrees: `feature-user-auth`, `bugfix-mobile-menu`
2. **Mantenha o repositório principal limpo** usando worktrees para desenvolvimento
3. **Use `--skip-node-modules`** para projetos grandes e instale dependências conforme necessário
4. **O comando `list` mostra onde você está** - útil quando trabalhando com múltiplos worktrees
5. **Commit suas mudanças** antes de remover worktrees para evitar perda de trabalho
