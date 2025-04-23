# tc-fiapeats-infra-gateway

Este projeto provisiona AWS Gateway utilizando Terraform que será utilizado no projeto fiapeats da fase 5, com o objetivo de expor duas rotas para gerenciamento de vídeos, com autenticação baseada em usuários autenticados via AWS Cognito.

---

📌 Visão Geral

Este API Gateway expõe as seguintes rotas:

* POST /upload: Cadastra os vídeos do cliente (pode enviar mais de um) .
* GET /upload: Retorna a lista de vídeos associados ao cliente.

Todas as rotas exigem autenticação via Cognito User Pool.

---

Fluxo de autenticação:

1. O usuário se autentica via Cognito
2. Recebe um token (JWT)
3. O token deve ser enviado no header de cada requisição

Para gerar o token utilizar a seguinte rota:

POST /https://cognito-idp.us-east-1.amazonaws.com/AuthenticationResult/AccessToken

Corpo da requisição:

```json
{
  "AuthFlow": "USER_PASSWORD_AUTH",
  "ClientId": "{{CLIENT_ID}}",
  "AuthParameters": {
    "USERNAME": "{{USERNAME}}",
    "PASSWORD": "{{PASSWORD}}",
    "SECRET_HASH":  "{{SECRET_HASH}}"
  }
}
```
---

🛣️ Endpoints

POST /upload

* Autenticação: via Header `Authorization: Bearer <token>`
* Máximo de 5 arquivos por requisição
* Tamanho máximo por vídeo: 50MB
* Content-Type: multipart/form-data
* Parâmetros: file (arquivo de vídeo a ser enviado)

Resposta de sucesso (200 OK):

```json
{
    "details": [
        {
            "video": "WhatsApp Video 2025-04-21 at 15.32.28.mp4",
            "details": "Nome: WhatsApp Video 2025-04-21 at 15.32.28.mp4, Tamanho: 0.11 MB, Usuário: teste@gmail.com",
            "status": "Sucesso"
        }
    ]
}
```

GET /upload

* Autenticação: via Header `Authorization: Bearer <token>`

Resposta de sucesso (200 OK):

```json
{
  "data": [
    {
        "nome": "video1.mp4",
        "status": "PENDENTE_PROCESSAMENTO",
        "url": ""
    },
    {
        "nome": "video2.mp4",
        "status": "PROCESSADO_COM_SUCESSO",
        "url": "http:videoprocessado"
    },
    {
        "nome": "video3.mp4",
        "status": "PROCESSADO_COM_ERRO",
        "url": ""
    }  
  ]
}
```

---

📦 Exemplo de Requisição com cURL

POST

```bash
curl --location 'https://sxvgkjrkwa.execute-api.us-east-1.amazonaws.com/upload' \
--header 'Authorization: Bearer <SEU_ID_TOKEN_AQUI>' \
--form 'file=@"/caminho/do/arquivo/video.mp4"'
```


GET

```bash
curl --location 'https://sxvgkjrkwa.execute-api.us-east-1.amazonaws.com/upload' \
--header 'Authorization: Bearer <SEU_ID_TOKEN_AQUI>'
```