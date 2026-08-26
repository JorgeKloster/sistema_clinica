# Controle Clinica

Projeto de criação de um sistema para clínicas integradas.

## Definição de Infra Inicial

1. Firebase - Sem custo, para uso durante o desenvolvimento
2. VPS - Deploy de primeira versão para uso em clínica
3. Futuramente migração para AWS, podendo escalar a aplicação de tamanho

## Definição de Banco de Dados e Back-end

### Bancos de Dados

#### SQL

PostgreSQL - Dados na nuvem

SQLite - Dados OFFLINE

#### noSQL

MongoDB -  exames digitalizados, imagens odontológicas, relatórios em PDF, registros de acesso, histórico de alterações em prontuários

Redis - acelerar consultas de agenda e disponibilidade, fila de sincronização

### Linguagem Back-End

Go

