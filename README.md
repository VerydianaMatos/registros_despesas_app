# Minhas Despesas

Aplicativo Flutter para registro de despesas pessoais, com autenticacao via Firebase Auth e armazenamento de dados no Cloud Firestore.

## Tema

Registro de despesas pessoais.

## Funcionalidades

- Login com e-mail e senha.
- Cadastro de nova conta com nome, e-mail e senha.
- Logout na tela principal.
- Rotas nomeadas para login, cadastro, lista de despesas e formulario.
- Navegacao com `pushNamed` e `pushNamedAndRemoveUntil`.
- Listagem de despesas usando `FutureBuilder`, com carregamento e mensagem de erro.
- Cadastro de despesas com descricao, categoria, valor em reais e data.
- Edicao de despesas cadastradas.
- Remocao de despesas.
- Filtro por categoria.
- Resumo com total, quantidade, media e maior categoria de gasto.
- Area de historico mensal com media dos gastos por mes.
- Dados separados por usuario autenticado.

## Tecnologias

- Flutter
- Firebase Auth
- Cloud Firestore
- Firebase Core

## Estrutura

```text
lib/
├── models/
│   └── despesa.dart
├── services/
│   ├── auth_service.dart
│   ├── despesa_service.dart
│   └── firebase_init_service.dart
├── screens/
│   ├── login_screen.dart
│   ├── cadastro_screen.dart
│   ├── despesa_screen.dart
│   └── despesa_form_screen.dart
├── firebase_options.dart
└── main.dart
```

## Requisitos atendidos

- Autenticacao com Firebase Auth.
- Tela de login.
- Tela de cadastro.
- Logout.
- Tratamento de erros de autenticacao.
- Rotas nomeadas: `/login`, `/cadastro`, `/despesas` e `/despesa-form`.
- Uso de `pushNamedAndRemoveUntil` apos login, cadastro e logout.
- Uso de `pushNamed` para navegar entre telas.
- Listagem de itens com `FutureBuilder`.
- Loading e tratamento de erro no `FutureBuilder`.
- Criacao de item no Firestore.
- Remocao de item no Firestore.
- Acesso ao Firestore somente pela classe `DespesaService`.
- Modelo `Despesa` com `fromMap()` e `toMap()`.

## Configuracao do Firebase

Para rodar o projeto, crie um projeto no Firebase e habilite:

- Authentication com provedor E-mail/senha.
- Cloud Firestore.

Depois adicione o arquivo `google-services.json` em:

```text
android/app/google-services.json
```

O arquivo `google-services.json` nao deve ser enviado para repositorios publicos.

## Como executar

Instale as dependencias:

```bash
flutter pub get
```

Execute o app:

```bash
flutter run
```

## Regras do Firestore

O projeto inclui um arquivo `firestore.rules` com regras para proteger os dados por usuario autenticado.
