# Sistema Clínica

Sistema web e multiplataforma para a gestão do dia a dia de clínicas que reúnem várias especialidades da saúde (odontologia, fisioterapia, nutrição, psicologia etc.) no mesmo espaço. Ele centraliza agenda, pacientes, profissionais, procedimentos, salas e o registro dos atendimentos.

---

## Sumário

1. [Descrição do projeto](#1-descrição-do-projeto)
2. [Problema](#2-problema)
3. [Justificativa](#3-justificativa)
4. [Tecnologias utilizadas](#4-tecnologias-utilizadas)
5. [Regras de negócio](#5-regras-de-negócio)
6. [Casos de uso](#6-casos-de-uso)
7. [Diagramas](#7-diagramas)
8. [Como executar o projeto](#8-como-executar-o-projeto)
9. [Estrutura do repositório](#9-estrutura-do-repositório)
10. [Endpoints da API](#10-endpoints-da-api)
11. [Próximos passos](#11-próximos-passos)

---

## 1. Descrição do projeto

O **Sistema Clínica** é composto por três partes:

- **Aplicativo cliente (Flutter):** interface usada por administradores, profissionais de saúde e recepcionistas. Roda no navegador (Flutter Web) e também pode ser compilado para Windows, macOS, Android e iOS.
- **API REST (Go):** concentra as regras de negócio, a autenticação por JWT e o controle de acesso por perfil.
- **Banco de dados (PostgreSQL):** guarda os dados da clínica. Ele também garante regras críticas diretamente no banco, como a proibição de horários sobrepostos e a trilha de auditoria.

Principais funcionalidades:

| Módulo | O que faz |
|---|---|
| **Autenticação** | Login com e-mail e senha, token JWT válido por 24 horas e sessão salva no dispositivo com armazenamento seguro. |
| **Tela inicial** | Saudação e lista dos agendamentos do dia. O profissional vê os próprios atendimentos; os demais perfis veem os da clínica. |
| **Agenda semanal** | Grade de segunda a sábado (domingo aparece quando há agendamento), das 8h às 19h, com filtro por profissional. Permite criar, editar, confirmar, cancelar e excluir agendamentos. |
| **Pacientes** | Cadastro com CPF, data de nascimento, sexo e contatos; ficha do paciente com histórico de atendimentos e informações de saúde (alergias, condições e medicamentos em uso). |
| **Atendimento** | Tela usada pelo profissional para iniciar e finalizar o atendimento, registrar anotações clínicas, consultar o histórico do paciente e atualizar as informações de saúde. |
| **Atendimentos em andamento** | Painel com um quadro por sala, mostrando o atendimento em curso (paciente, procedimento, profissional e tempo decorrido) ou o próximo agendamento do dia. Atualiza sozinho a cada 15 segundos. |
| **Profissionais** | Cadastro de usuários com perfil (administrador, profissional de saúde ou recepcionista) e especialidade. |
| **Especialidades** | Lista de especialidades de cada clínica, criada com valores padrão e editável pelo administrador. |
| **Procedimentos** | Nome, descrição, valor, duração sugerida e sala onde é realizado. |
| **Salas e recursos** | Salas da clínica com tipo (consultório médico, odontológico, fisioterapia etc.) e lista de equipamentos. |
| **Auditoria** | Toda inclusão, alteração e exclusão nas tabelas principais fica registrada com o autor e os dados antes e depois da mudança. |

---

## 2. Problema

Clínicas integradas dividem a mesma estrutura física (salas, equipamentos e recepção) entre profissionais de especialidades diferentes. Na prática, a gestão desse espaço costuma ser feita com agendas de papel, planilhas ou ferramentas genéricas de calendário, o que causa problemas recorrentes:

- **Conflitos de horário:** o mesmo profissional ou a mesma sala acabam reservados para dois atendimentos ao mesmo tempo, e o erro só aparece quando o paciente chega.
- **Uso ineficiente das salas:** sem saber qual sala e quais equipamentos cada procedimento exige, a recepção não consegue distribuir os atendimentos de forma organizada.
- **Informações do paciente espalhadas:** alergias, condições de saúde, medicamentos e anotações de consultas anteriores ficam em fichas separadas por especialidade, ou nem são registradas. O profissional pode não ter acesso a dados importantes para a segurança do atendimento.
- **Pouca visibilidade da operação:** o gestor não sabe em tempo real quais salas estão ocupadas, quais atendimentos já começaram e quanto tempo estão levando.
- **Falta de rastreabilidade:** em planilhas e papel não há registro confiável de quem alterou um agendamento ou um dado do paciente, nem de quando a alteração foi feita.

**Necessidade identificada:** um sistema único, acessível pelo navegador e com perfis de acesso, que organize agenda, pessoas e recursos da clínica, impeça conflitos de forma automática e mantenha o histórico do paciente disponível no momento do atendimento.

---

## 3. Justificativa

O projeto é importante porque trata de pontos que afetam diretamente a qualidade do atendimento e a eficiência da clínica:

- **Segurança do paciente:** alergias, condições e medicamentos ficam visíveis na tela de atendimento, junto com o histórico das consultas anteriores em todas as especialidades.
- **Fim dos conflitos de agenda:** a sobreposição de horários de um profissional ou de uma sala é bloqueada pelo próprio banco de dados (restrições de exclusão do PostgreSQL). A regra vale mesmo se duas pessoas tentarem agendar ao mesmo tempo.
- **Melhor aproveitamento da estrutura:** cada procedimento é ligado a uma sala com tipo e recursos definidos, e o painel de atendimentos mostra a ocupação das salas em tempo real.
- **Rastreabilidade e conformidade:** a trilha de auditoria registra quem fez cada alteração e o que mudou. Isso apoia boas práticas de proteção de dados pessoais e de saúde, como as previstas na LGPD.
- **Preservação do histórico clínico:** pacientes, profissionais e procedimentos com atendimentos vinculados não podem ser excluídos. Agendamentos são cancelados em vez de apagados, mantendo o registro.
- **Acesso multiplataforma e baixo custo:** a mesma base de código Flutter atende navegador, desktop e celular. A implantação usa ferramentas livres (Go, PostgreSQL, Caddy e Docker) em um servidor VPS simples.
- **Pronto para várias clínicas:** os dados são separados por clínica (*multi-tenant*). A clínica de cada usuário vem do token, e a API nunca a lê do corpo da requisição.

**Benefícios esperados:** menos faltas e retrabalho por erros de agenda, atendimentos mais seguros e rápidos, visão gerencial da ocupação da clínica e redução do uso de papel e planilhas.

---

## 4. Tecnologias utilizadas

### Front-end

| Tecnologia | Uso |
|---|---|
| **Flutter** (Dart SDK ^3.7.2) | Interface multiplataforma: Web, Windows, macOS, Android e iOS |
| `http` ^1.6.0 | Comunicação com a API REST |
| `flutter_secure_storage` ^11.2.0 | Armazenamento seguro do token JWT e dos dados da sessão |
| `intl` ^0.20.2 | Formatação de datas, horas e valores em português |

### Back-end

| Tecnologia | Uso |
|---|---|
| **Go** 1.27 (`net/http` da biblioteca padrão) | API REST |
| `golang-jwt/jwt` v5 | Geração e validação de tokens JWT (HS256) |
| `golang.org/x/crypto/bcrypt` | Hash das senhas |
| `lib/pq` | Driver do PostgreSQL |
| `rs/cors` | Configuração de CORS |
| `joho/godotenv` | Leitura de variáveis de ambiente de arquivos `.env` |

### Banco de dados

| Tecnologia | Uso |
|---|---|
| **PostgreSQL 18** | Banco relacional principal |
| Extensão `btree_gist` | Restrições `EXCLUDE` que impedem horários sobrepostos |
| Gatilhos (*triggers*) PL/pgSQL | Auditoria, `updated_at` automático e dados padrão para novas clínicas |
| **golang-migrate** | Versionamento do esquema (16 migrations em `go-backend/migrations`) |

### Infraestrutura

| Tecnologia | Uso |
|---|---|
| **Docker** e **Docker Compose** | Contêineres do back-end, banco, migrations e servidor web, com perfis `dev` e `prod` |
| **Caddy 2** | Servidor web e proxy reverso, com HTTPS automático. Entrega o Flutter Web e encaminha `/api/*` para o back-end |
| **DuckDNS** | Domínio dinâmico usado no ambiente de produção (VPS) |

---

## 5. Regras de negócio

### Acesso e usuários

| Código | Regra |
|---|---|
| **RN01** | Todas as rotas exigem autenticação por token JWT, exceto login e cadastro inicial. O token expira em 24 horas; quando a API responde 401, o aplicativo encerra a sessão e volta ao login. |
| **RN02** | Existem três perfis: **administrador** (`admin`), **profissional de saúde** (`doctor`) e **recepcionista** (`receptionist`). |
| **RN03** | O cadastro público (`/users/register`) só funciona enquanto não existir nenhum usuário no sistema. Ele cria o primeiro administrador. Depois disso, novos usuários só podem ser criados por um administrador. |
| **RN04** | Somente administradores podem gerenciar profissionais, especialidades, procedimentos, salas e tipos de sala, e excluir agendamentos. |
| **RN05** | Cada usuário só acessa os dados da própria clínica. A clínica vem sempre do token, nunca do corpo da requisição. |
| **RN06** | O e-mail do usuário é único no sistema. A senha precisa ter pelo menos 8 caracteres e é guardada apenas como hash bcrypt. A API nunca devolve a senha nem o hash. |
| **RN07** | Na edição de um usuário, deixar a senha em branco mantém a senha atual. |
| **RN08** | Um administrador não pode excluir o próprio usuário nem remover o próprio perfil de administrador. |
| **RN09** | O profissional de saúde precisa ter uma especialidade, e ela precisa estar cadastrada na clínica. Outros perfis não têm especialidade. |
| **RN10** | Um profissional com agendamentos ou registros vinculados não pode ser excluído. |

### Especialidades, salas e procedimentos

| Código | Regra |
|---|---|
| **RN11** | Uma clínica nova recebe automaticamente as especialidades padrão (Dentista, Fisioterapeuta, Oftalmologista, Dermatologista, Nutricionista, Psicólogo, Fonoaudiólogo e Clínico Geral) e os tipos de sala padrão (consultório médico, consultório odontológico, sala de fisioterapia, sala de exames e sala de procedimentos). |
| **RN12** | Nomes de especialidades, tipos de sala e salas não se repetem dentro da mesma clínica, sem diferenciar maiúsculas e minúsculas, e têm no máximo 100 caracteres. |
| **RN13** | Uma especialidade usada por algum profissional não pode ser excluída. Um tipo de sala usado por alguma sala também não. |
| **RN14** | Toda sala tem um tipo e pode ter uma lista de recursos e equipamentos (um por linha). |
| **RN15** | Uma sala usada por procedimentos ou agendamentos não pode ser excluída. |
| **RN16** | Todo procedimento tem nome e sala obrigatórios. O valor não pode ser negativo e a duração sugerida fica entre 5 e 480 minutos (padrão de 60). |
| **RN17** | Um procedimento com agendamentos não pode ser excluído. |

### Pacientes

| Código | Regra |
|---|---|
| **RN18** | O CPF do paciente é único dentro da clínica. |
| **RN19** | Um paciente com agendamentos não pode ser excluído, para preservar o histórico clínico. |
| **RN20** | Alergias, condições de saúde e medicamentos são registrados como listas (um item por linha). O sistema guarda quem fez a última alteração e quando. |

### Agendamentos e atendimentos

| Código | Regra |
|---|---|
| **RN21** | Todo agendamento tem paciente, profissional de saúde, procedimento, sala e horários de início e fim. Paciente, profissional, procedimento e sala precisam pertencer à clínica do usuário. |
| **RN22** | Só usuários com o perfil profissional de saúde podem receber agendamentos. |
| **RN23** | O horário de fim deve ser depois do início, e o agendamento deve começar e terminar no mesmo dia. |
| **RN24** | Não é possível criar um agendamento no passado nem mover um agendamento existente para o passado. Agendamentos que já passaram ainda podem ter outros dados corrigidos. |
| **RN25** | Se a sala não for informada, o agendamento usa a sala sugerida pelo procedimento. A duração sugerida do procedimento preenche o horário de fim, que pode ser ajustado. |
| **RN26** | Um profissional não pode ter dois agendamentos com horários sobrepostos. |
| **RN27** | Uma sala não pode ter dois agendamentos com horários sobrepostos. |
| **RN28** | Agendamentos cancelados liberam o horário do profissional e da sala. Ao reativar um agendamento cancelado, as RN26 e RN27 são verificadas de novo. |
| **RN29** | Os status possíveis são: **agendado**, **confirmado**, **em atendimento**, **concluído** e **cancelado**. Ao iniciar o atendimento, o sistema grava o horário real de início; ao concluir, o horário real de término. |
| **RN30** | No dia a dia, agendamentos são cancelados e não excluídos, para manter o histórico. A exclusão definitiva é restrita ao administrador. |
| **RN31** | Os horários são guardados no fuso da clínica (`CLINIC_TIMEZONE`, padrão `America/Sao_Paulo`). |
| **RN32** | O histórico do paciente mostra os atendimentos anteriores em ordem cronológica, sem os cancelados. |
| **RN33** | A consulta da agenda aceita períodos de no máximo 62 dias e não mostra agendamentos cancelados. |

### Auditoria

| Código | Regra |
|---|---|
| **RN34** | Toda inclusão, alteração e exclusão em clínicas, usuários, pacientes, procedimentos e agendamentos gera um registro em `audit_log`. O registro guarda a tabela, a ação, o identificador, nome e e-mail do autor, a data e os dados antes e depois em JSON. |
| **RN35** | O autor de cada alteração (`updated_by`) vem do usuário do token, nunca do corpo da requisição. |

---

## 6. Casos de uso

### Atores

| Ator | Descrição |
|---|---|
| **Administrador** | Gestor da clínica. Tem acesso a todas as funcionalidades, inclusive cadastros estruturais (profissionais, procedimentos e salas). |
| **Profissional de saúde** | Dentista, fisioterapeuta, nutricionista etc. Atende os pacientes, registra anotações e consulta sua agenda. |
| **Recepcionista** | Faz o atendimento de balcão: cadastra pacientes e gerencia agendamentos. |

> Profissional de saúde e recepcionista compartilham as funções operacionais (agenda, pacientes e atendimento). O administrador tem, além dessas, as funções de gestão.

### Resumo

| ID | Caso de uso | Atores |
|---|---|---|
| UC01 | Realizar cadastro inicial | Administrador |
| UC02 | Autenticar-se no sistema | Todos |
| UC03 | Gerenciar profissionais | Administrador |
| UC04 | Gerenciar especialidades | Administrador |
| UC05 | Gerenciar salas e tipos de sala | Administrador |
| UC06 | Gerenciar procedimentos | Administrador |
| UC07 | Gerenciar pacientes | Todos |
| UC08 | Consultar agenda semanal | Todos |
| UC09 | Agendar procedimento | Todos |
| UC10 | Alterar, confirmar ou cancelar agendamento | Todos |
| UC11 | Excluir agendamento | Administrador |
| UC12 | Realizar atendimento | Profissional de saúde |
| UC13 | Atualizar informações de saúde do paciente | Todos |
| UC14 | Acompanhar atendimentos em andamento | Administrador |

### Detalhamento dos principais casos de uso

#### UC02: Autenticar-se no sistema
- **Ator:** qualquer usuário cadastrado.
- **Pré-condição:** o usuário tem cadastro ativo.
- **Fluxo principal:**
  1. O usuário informa e-mail e senha na tela de login.
  2. O sistema valida as credenciais e gera um token JWT válido por 24 horas.
  3. O aplicativo guarda o token de forma segura e abre a tela inicial com os agendamentos do dia.
- **Fluxo alternativo:**
  - 2a. Credenciais inválidas: o sistema mostra uma mensagem de erro e continua na tela de login.
  - Token expirado em qualquer momento: o aplicativo encerra a sessão e volta ao login (RN01).

#### UC09: Agendar procedimento
- **Atores:** recepcionista, profissional de saúde ou administrador.
- **Pré-condição:** usuário autenticado; paciente, profissional, procedimento e sala cadastrados.
- **Fluxo principal:**
  1. O usuário toca em um horário vazio da agenda, usa o botão "Novo agendamento" ou escolhe "Agendar procedimento" na ficha do paciente.
  2. O usuário escolhe paciente, profissional e procedimento.
  3. O sistema preenche a sala sugerida e o horário de fim de acordo com a duração do procedimento (RN25).
  4. O usuário ajusta data, horários e observações, se precisar, e confirma.
  5. O sistema valida as regras RN21 a RN24 e grava o agendamento com o status "agendado".
  6. O agendamento aparece na grade semanal.
- **Fluxos alternativos:**
  - 5a. O profissional já tem atendimento no horário: o sistema avisa e não grava (RN26).
  - 5b. A sala já está ocupada no horário: o sistema avisa e não grava (RN27).
  - 5c. Data ou horário no passado: o sistema avisa e não grava (RN24).

#### UC10: Alterar, confirmar ou cancelar agendamento
- **Atores:** recepcionista, profissional de saúde ou administrador.
- **Fluxo principal:**
  1. O usuário toca em um agendamento na agenda.
  2. O sistema mostra os detalhes e as ações "Confirmar", "Editar" e "Cancelar agendamento" (e "Excluir" para o administrador).
  3. O usuário escolhe a ação; no cancelamento, o sistema pede confirmação.
  4. O sistema grava a mudança e libera o horário quando o agendamento é cancelado (RN28).
- **Fluxo alternativo:**
  - 3a. Na edição, valem as mesmas validações do UC09.

#### UC12: Realizar atendimento
- **Ator:** profissional de saúde.
- **Pré-condição:** existe um agendamento do paciente com o status "agendado" ou "confirmado".
- **Fluxo principal:**
  1. O profissional abre o agendamento pela tela inicial ou pela agenda.
  2. O sistema mostra os dados do paciente, as informações de saúde e o histórico de atendimentos anteriores.
  3. O profissional seleciona "Iniciar atendimento"; o sistema muda o status para "em atendimento" e grava o horário real de início (RN29).
  4. O profissional registra as anotações clínicas e, se necessário, atualiza as informações de saúde (UC13).
  5. O profissional seleciona "Finalizar atendimento" e confirma; o sistema muda o status para "concluído" e grava o horário real de término.
- **Fluxo alternativo:**
  - 1a. Agendamento cancelado: a tela mostra o aviso de cancelamento e bloqueia a edição.

#### UC14: Acompanhar atendimentos em andamento
- **Ator:** administrador.
- **Fluxo principal:**
  1. O administrador abre o painel "Atendimentos em andamento".
  2. O sistema mostra um quadro por sala: o atendimento em curso (paciente, procedimento, profissional e tempo decorrido) ou o próximo agendamento do dia.
  3. O painel se atualiza sozinho a cada 15 segundos.

#### UC03: Gerenciar profissionais
- **Ator:** administrador.
- **Fluxo principal:**
  1. O administrador abre "Gerenciamento > Profissionais".
  2. O sistema lista os usuários da clínica.
  3. O administrador cadastra, edita ou exclui um profissional, informando nome, e-mail, telefone, perfil, especialidade e senha.
  4. O sistema valida as regras RN06 a RN10 e grava a mudança.
- **Fluxos alternativos:**
  - 4a. E-mail já cadastrado: o sistema avisa e não grava.
  - 4b. Profissional com agendamentos vinculados: o sistema impede a exclusão.

---

## 7. Diagramas

> Os diagramas usam **Mermaid**, que o GitHub mostra diretamente na página do repositório. A planilha `Database_schema.xlsx` traz o dicionário de dados do banco.

### 7.1 Arquitetura do sistema

```mermaid
flowchart LR
    subgraph Cliente
        A[App Flutter<br/>Web / Desktop / Mobile]
    end

    subgraph Servidor["Servidor (Docker Compose)"]
        C[Caddy 2<br/>HTTPS + arquivos do Flutter Web]
        B[API REST em Go<br/>:8080]
        D[(PostgreSQL 18)]
        M[golang-migrate]
    end

    A -- "HTTPS /" --> C
    A -- "HTTPS /api/* (JWT)" --> C
    C -- "reverse_proxy" --> B
    B -- "SQL" --> D
    M -- "aplica migrations" --> D
```

### 7.2 Diagrama de casos de uso

```mermaid
flowchart LR
    ADM([👤 Administrador])
    PRO([👤 Profissional de saúde])
    REC([👤 Recepcionista])

    subgraph Sistema["Sistema Clínica"]
        UC01(UC01 Cadastro inicial)
        UC02(UC02 Autenticar-se)
        UC03(UC03 Gerenciar profissionais)
        UC04(UC04 Gerenciar especialidades)
        UC05(UC05 Gerenciar salas e tipos)
        UC06(UC06 Gerenciar procedimentos)
        UC07(UC07 Gerenciar pacientes)
        UC08(UC08 Consultar agenda)
        UC09(UC09 Agendar procedimento)
        UC10(UC10 Alterar / confirmar / cancelar agendamento)
        UC11(UC11 Excluir agendamento)
        UC12(UC12 Realizar atendimento)
        UC13(UC13 Atualizar informações de saúde)
        UC14(UC14 Acompanhar atendimentos em andamento)
    end

    ADM --- UC01 & UC03 & UC04 & UC05 & UC06 & UC11 & UC14
    ADM --- UC02 & UC07 & UC08 & UC09 & UC10 & UC13
    REC --- UC02 & UC07 & UC08 & UC09 & UC10 & UC13
    PRO --- UC02 & UC07 & UC08 & UC09 & UC10 & UC12 & UC13
```

### 7.3 Modelo entidade-relacionamento

```mermaid
erDiagram
    CLINIC ||--o{ USERS : possui
    CLINIC ||--o{ PATIENT : atende
    CLINIC ||--o{ SPECIALTY : oferece
    CLINIC ||--o{ ROOM_TYPE : define
    CLINIC ||--o{ ROOM : possui
    CLINIC ||--o{ PROCEDURE : oferece
    CLINIC ||--o{ APPOINTMENT : agenda
    ROOM_TYPE ||--o{ ROOM : classifica
    ROOM ||--o{ PROCEDURE : "sala sugerida"
    ROOM ||--o{ APPOINTMENT : ocupa
    PATIENT ||--o{ APPOINTMENT : recebe
    USERS ||--o{ APPOINTMENT : "atende (doctor)"
    PROCEDURE ||--o{ APPOINTMENT : "é realizado em"

    CLINIC {
        int clinic_id PK
        varchar name
        varchar address
        varchar phone
        int updated_by FK
    }
    USERS {
        int user_id PK
        int clinic_id FK
        varchar first_name
        varchar last_name
        varchar email UK
        varchar phone
        varchar password_hash
        varchar role "admin | doctor | receptionist"
        varchar specialty
        int updated_by FK
    }
    SPECIALTY {
        int specialty_id PK
        int clinic_id FK
        varchar name "único por clínica"
    }
    PATIENT {
        int patient_id PK
        int clinic_id FK
        varchar first_name
        varchar last_name
        varchar cpf "único por clínica"
        date birth_date
        varchar gender
        varchar email
        varchar phone
        text allergies
        text medical_conditions
        text medications
        timestamp health_updated_at
        int health_updated_by FK
    }
    ROOM_TYPE {
        int room_type_id PK
        int clinic_id FK
        varchar name
    }
    ROOM {
        int room_id PK
        int clinic_id FK
        int room_type_id FK
        varchar name
        text resources
    }
    PROCEDURE {
        int procedure_id PK
        int clinic_id FK
        int room_id FK
        varchar name
        text description
        numeric price
        int duration_minutes "5 a 480"
    }
    APPOINTMENT {
        int appointment_id PK
        int clinic_id FK
        int patient_id FK
        int doctor_id FK
        int procedure_id FK
        int room_id FK
        timestamp starts_at
        timestamp ends_at
        varchar status
        text notes
        timestamp started_at
        timestamp finished_at
        text clinical_notes
        int updated_by FK
    }
    AUDIT_LOG {
        int log_id PK
        text table_name
        text action "insert | update | delete"
        int changed_by_id
        text changed_by_name
        text changed_by_email
        timestamp changed_at
        jsonb old_data
        jsonb new_data
    }
```

> `AUDIT_LOG` é alimentada por gatilhos e não tem chave estrangeira, para que o histórico continue existindo mesmo se o usuário autor for removido.

### 7.4 Ciclo de vida do agendamento

```mermaid
stateDiagram-v2
    state "Agendado (scheduled)" as Agendado
    state "Confirmado (confirmed)" as Confirmado
    state "Em atendimento (in_progress)" as EmAtendimento
    state "Concluído (completed)" as Concluido
    state "Cancelado (canceled)" as Cancelado

    [*] --> Agendado : criar agendamento
    Agendado --> Confirmado : confirmar
    Agendado --> EmAtendimento : iniciar atendimento
    Confirmado --> EmAtendimento : iniciar atendimento (grava started_at)
    EmAtendimento --> Concluido : finalizar atendimento (grava finished_at)
    Agendado --> Cancelado : cancelar
    Confirmado --> Cancelado : cancelar
    Cancelado --> Agendado : reativar (revalida conflitos)
    Concluido --> [*]
```

### 7.5 Sequência: criação de um agendamento

```mermaid
sequenceDiagram
    actor U as Recepcionista
    participant App as App Flutter
    participant API as API Go
    participant DB as PostgreSQL

    U->>App: Preenche paciente, profissional,<br/>procedimento, data e horário
    App->>API: POST /appointments/create (Bearer JWT)
    API->>API: Valida token e extrai clinic_id / user_id
    API->>API: Valida campos, mesmo dia e horário futuro
    API->>DB: Verifica se paciente, profissional,<br/>procedimento e sala são da clínica
    DB-->>API: OK (sala sugerida do procedimento)
    API->>DB: INSERT INTO appointment
    alt Horário livre
        DB-->>API: Sucesso (gatilho grava audit_log)
        API-->>App: 201 Created
        App-->>U: Agendamento aparece na agenda
    else Sobreposição (EXCLUDE constraint)
        DB-->>API: Erro 23P01
        API-->>App: 409 "Profissional/sala já ocupado neste horário"
        App-->>U: Mostra a mensagem de conflito
    end
```

### 7.6 Sequência: autenticação

```mermaid
sequenceDiagram
    actor U as Usuário
    participant App as App Flutter
    participant API as API Go
    participant DB as PostgreSQL

    U->>App: E-mail e senha
    App->>API: POST /users/login
    API->>DB: Busca usuário pelo e-mail
    DB-->>API: Dados + password_hash
    API->>API: Compara a senha com bcrypt
    API-->>App: 200 { token JWT (24h), user }
    App->>App: Salva o token no armazenamento seguro
    App-->>U: Abre a tela inicial
```

---

## 8. Como executar o projeto

### 8.1 Pré-requisitos

| Ferramenta | Versão | Necessária para |
|---|---|---|
| [Git](https://git-scm.com/) | qualquer recente | Clonar o repositório |
| [Docker](https://docs.docker.com/get-docker/) + Docker Compose v2 | recente | Banco, migrations e back-end |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | com Dart **3.7.2 ou superior** | Aplicativo cliente |
| Google Chrome ou Microsoft Edge | recente | Rodar o Flutter Web |
| [Go](https://go.dev/dl/) | **1.27.1** | *Opcional:* só para rodar o back-end fora do Docker |

Para conferir as instalações:

```bash
docker --version
docker compose version
flutter doctor
```

### 8.2 Clonar o repositório

```bash
git clone https://github.com/JorgeKloster/sistema_clinica.git
cd sistema_clinica
```

### 8.3 Configurar o ambiente

Crie o arquivo **`.env.dev`** na raiz do projeto. Ele está no `.gitignore` e não é versionado.

```env
# Banco de dados
POSTGRES_USER=clinica
POSTGRES_PASSWORD=troque_esta_senha
POSTGRES_DB=clinica

# Volume onde o PostgreSQL guarda os dados (volume nomeado do Docker)
DB_VOLUME=pgdata:/var/lib/postgresql

# Segredo usado para assinar os tokens JWT (use um valor longo e aleatório)
JWT_SECRET=troque_por_um_segredo_longo_e_aleatorio
```

| Variável | Descrição |
|---|---|
| `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | Credenciais e nome do banco. O back-end recebe os mesmos valores como `DB_USER`, `DB_PASSWORD` e `DB_NAME`. |
| `DB_VOLUME` | Mapeamento do volume de dados do PostgreSQL. |
| `JWT_SECRET` | Chave secreta dos tokens. Para gerar uma: `openssl rand -hex 32`. |
| `CLINIC_TIMEZONE` | Já definida no `docker-compose.yml` como `America/Sao_Paulo`. |

### 8.4 Subir banco, migrations e back-end (perfil `dev`)

```bash
# 1. Sobe o PostgreSQL
docker compose --env-file .env.dev --profile dev up -d db-local

# 2. Aplica as migrations (aguarde alguns segundos após o passo 1)
docker compose --env-file .env.dev --profile dev run --rm migrate-local

# 3. Compila e sobe a API Go na porta 8080
docker compose --env-file .env.dev --profile dev up -d --build backend-local
```

> Se o passo 2 falhar com erro de conexão, o banco ainda está iniciando. Aguarde alguns segundos e repita o comando.

Para ver os logs da API:

```bash
docker compose --env-file .env.dev --profile dev logs -f backend-local
```

A API fica disponível em **http://localhost:8080** e o banco em **localhost:5432**.

### 8.5 Criar a clínica e o primeiro administrador

Na primeira execução, o banco está vazio. Faça estes dois passos uma única vez.

**a) Cadastre a clínica direto no banco.** As especialidades e os tipos de sala padrão são criados automaticamente:

```bash
docker compose --env-file .env.dev --profile dev exec db-local \
  psql -U clinica -d clinica \
  -c "INSERT INTO clinic (name, address, phone) VALUES ('Clínica Bucalle', 'Rua Exemplo, 123', '(00) 0000-0000') RETURNING clinic_id;"
```

**b) Crie o administrador pela API.** O endpoint só aceita a chamada enquanto não houver nenhum usuário (RN03). O campo `password_hash` recebe a senha em texto puro, e a API gera o hash.

```bash
curl -X POST http://localhost:8080/users/register \
  -H "Content-Type: application/json" \
  -d '{
        "clinic_id": 1,
        "first_name": "Admin",
        "last_name": "Clínica",
        "email": "admin@clinica.com",
        "phone": "",
        "password_hash": "senha12345"
      }'
```

> No PowerShell do Windows, use `curl.exe` e escreva o JSON em uma única linha, com as aspas internas escapadas (`\"`).

Depois disso, entre no aplicativo com `admin@clinica.com` / `senha12345` e cadastre os demais profissionais, as salas e os procedimentos pela interface.

### 8.6 Executar o aplicativo Flutter

```bash
cd controle_clinica
flutter pub get
flutter run -d chrome
```

Por padrão, o aplicativo usa a API em `http://localhost:8080`, definida em `lib/config.dart`. Para usar outro endereço:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://192.168.0.10:8080
```

Outras plataformas (quando o ambiente está configurado no `flutter doctor`):

```bash
flutter run -d windows     # Desktop Windows
flutter run -d macos       # Desktop macOS
flutter run -d <id>        # Emulador ou dispositivo Android/iOS (veja: flutter devices)
```

> No emulador Android, `localhost` aponta para o próprio emulador. Use `--dart-define=API_BASE_URL=http://10.0.2.2:8080`.

**Ordem recomendada para testar:** cadastre as salas, depois os procedimentos (que exigem sala), os profissionais de saúde (que exigem especialidade) e os pacientes. Em seguida, crie agendamentos na agenda e realize um atendimento.

### 8.7 (Opcional) Rodar o back-end sem Docker

Com o banco do passo 8.4 rodando, crie dois arquivos `.env` (também ignorados pelo Git):

`go-backend/db/.env`
```env
DB_HOST=localhost
DB_USER=clinica
DB_PASSWORD=troque_esta_senha
DB_NAME=clinica
DB_SSLMODE=disable
```

`go-backend/middleware/.env`
```env
JWT_SECRET=troque_por_um_segredo_longo_e_aleatorio
```

Depois, execute **a partir da pasta `go-backend`** (os caminhos dos `.env` são relativos a ela):

```bash
cd go-backend
go mod download
go run main.go
```

> Pare o contêiner `backend-local` antes, para liberar a porta 8080.

### 8.8 Implantação em produção (perfil `prod`)

O perfil `prod` sobe o banco (sem expor a porta), as migrations, a API (sem expor a porta) e o **Caddy**, que entrega o Flutter Web com HTTPS automático e encaminha `/api/*` para a API.

1. Aponte o domínio para o IP do servidor e ajuste o nome do domínio na primeira linha de `caddy/Caddyfile`. O padrão é `clinica-jfk.duckdns.org`.
2. Gere o build web apontando para o caminho `/api` do domínio e copie o resultado para a pasta `web/` na raiz do projeto, que o Caddy serve:
   ```bash
   cd controle_clinica
   flutter build web --release --dart-define=API_BASE_URL=https://SEU_DOMINIO/api
   cd ..
   mkdir -p web && cp -r controle_clinica/build/web/* web/
   ```
3. Crie o arquivo `.env.prod`, com as mesmas variáveis do `.env.dev` e senhas fortes.
4. Suba os serviços:
   ```bash
   docker compose --env-file .env.prod --profile prod up -d db
   docker compose --env-file .env.prod --profile prod run --rm migrate
   docker compose --env-file .env.prod --profile prod up -d --build backend web
   ```
5. Faça o cadastro inicial (passo 8.5) usando `db` no lugar de `db-local` e `https://SEU_DOMINIO/api/users/register` como URL.

### 8.9 Comandos úteis

```bash
# Parar os serviços de desenvolvimento
docker compose --env-file .env.dev --profile dev down

# Apagar também os dados do banco (cuidado: irreversível)
docker compose --env-file .env.dev --profile dev down -v

# Desfazer a última migration
docker compose --env-file .env.dev --profile dev run --rm migrate-local \
  -path /migrations -database "postgres://clinica:troque_esta_senha@db-local:5432/clinica?sslmode=disable" down 1
```

---

## 9. Estrutura do repositório

```
sistema_clinica/
├── docker-compose.yml          # Serviços e perfis dev / prod
├── caddy/Caddyfile             # Servidor web + proxy reverso (produção)
├── Database_schema.xlsx        # Dicionário de dados
├── go-backend/                 # API REST em Go
│   ├── main.go                 # Ponto de entrada, CORS e servidor HTTP
│   ├── Dockerfile
│   ├── db/connection.go        # Conexão com o PostgreSQL
│   ├── middleware/jwt.go       # Validação do token JWT
│   ├── routes/router.go        # Registro das rotas
│   ├── handlers/               # Regras de negócio por recurso
│   │   ├── users.go            # Login, cadastro inicial e profissionais
│   │   ├── patient.go          # Pacientes e informações de saúde
│   │   ├── appointment.go      # Agenda, status, histórico e anotações
│   │   ├── procedure.go        # Procedimentos
│   │   ├── room.go             # Salas, tipos de sala e painel ao vivo
│   │   ├── specialty.go        # Especialidades
│   │   ├── clinic.go           # Clínicas
│   │   └── helpers.go          # Permissões, fuso horário e erros do Postgres
│   ├── models/                 # Estruturas de dados
│   └── migrations/             # 16 migrations versionadas (up/down)
└── controle_clinica/           # Aplicativo Flutter
    ├── lib/
    │   ├── main.dart           # Rotas e proteção de telas por login
    │   ├── config.dart         # URL da API (API_BASE_URL)
    │   ├── models/             # Modelos (paciente, agendamento...)
    │   ├── services/           # Chamadas à API e autenticação
    │   ├── pages/
    │   │   ├── login/          # Login
    │   │   ├── dentist/        # Tela inicial (agenda do dia)
    │   │   ├── common/         # Agenda, pacientes, ficha e atendimento
    │   │   └── admin/          # Profissionais, procedimentos, salas e painel ao vivo
    │   ├── widgets/            # Componentes reutilizáveis (grade semanal, menu, diálogos...)
    │   ├── theme/              # Tema visual
    │   └── utils/              # Formatadores (CPF, telefone, datas)
    ├── assets/images/          # Logotipo
    └── web/ windows/ macos/ android/ ios/   # Plataformas suportadas
```

---

## 10. Endpoints da API

Todas as rotas, exceto as públicas, exigem o cabeçalho `Authorization: Bearer <token>`. Rotas de alteração identificam o registro pelo parâmetro `?id=`.

| Recurso | Método e rota | Acesso |
|---|---|---|
| Autenticação | `POST /users/login` | Público |
| | `POST /users/register` | Público (só o primeiro usuário) |
| Profissionais | `GET /users` | Autenticado |
| | `POST /users/create` · `PUT /users/update` · `DELETE /users/delete` | Admin |
| Especialidades | `GET /specialties` | Autenticado |
| | `POST /specialties/create` · `DELETE /specialties/delete` | Admin |
| Pacientes | `GET /patients` · `POST /patients/create` · `PUT /patients/update` · `DELETE /patients/delete` | Autenticado |
| | `PUT /patients/health` | Autenticado |
| Procedimentos | `GET /procedures` | Autenticado |
| | `POST /procedures/create` · `PUT /procedures/update` · `DELETE /procedures/delete` | Admin |
| Tipos de sala | `GET /room-types` | Autenticado |
| | `POST /room-types/create` · `DELETE /room-types/delete` | Admin |
| Salas | `GET /rooms` · `GET /rooms/live` | Autenticado |
| | `POST /rooms/create` · `PUT /rooms/update` · `DELETE /rooms/delete` | Admin |
| Agendamentos | `GET /appointments?from=AAAA-MM-DD&to=AAAA-MM-DD[&doctor_id=]` | Autenticado |
| | `GET /appointments/get` · `GET /appointments/history?patient_id=` | Autenticado |
| | `POST /appointments/create` · `PUT /appointments/update` | Autenticado |
| | `PUT /appointments/status` · `PUT /appointments/clinical-notes` | Autenticado |
| | `DELETE /appointments/delete` | Admin |
| Clínicas | `GET /clinics` · `POST /clinics/create` | Autenticado |

**Códigos de resposta usados:** `200`/`201`/`204` sucesso · `400` dados inválidos · `401` sem token ou token inválido · `403` acesso restrito · `404` não encontrado · `409` conflito (horário ocupado, registro duplicado ou registro com vínculos).

---

## 11. Próximos passos

O menu lateral já mostra itens planejados que ainda não foram implementados nesta versão:

- **Relatórios:** financeiro, atendimentos e estatísticas de pacientes.
- **Administração:** controle de acesso detalhado, configurações da clínica e integrações.
- **Comunicação:** mensagens internas e notificações aos pacientes (lembretes de consulta).
- **Documentação:** protocolos médicos e documentos da clínica.
- **Fotos do atendimento:** o campo já existe na tela de atendimento; falta o armazenamento das imagens, planejado em MongoDB junto com exames digitalizados e relatórios em PDF.
- **Menus por perfil:** exibir no menu lateral apenas as opções de cada perfil. Hoje as restrições são aplicadas pela API.
- **Desempenho e modo offline:** Redis para cache de agenda e disponibilidade, e SQLite para uso sem conexão, com fila de sincronização.
- **Escalabilidade:** migração da VPS para a AWS conforme a demanda crescer.
